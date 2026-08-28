#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
platform=""
environment=""
audience=""
dry_run=false
push_tag=false
confirm_store=false

print_usage() {
  cat <<'EOF'
Build và delivery adapter cho Flutter base.

Cách dùng khuyến nghị:
  ./build.sh distribute --platform <android|ios|all> \
    --environment <dev|staging|prod> \
    --audience <tester|client> [--push-tag] [--dry-run]

  ./build.sh store --platform <android|ios|all> \
    --confirm-store [--push-tag] [--dry-run]

Ví dụ:
  ./build.sh distribute --platform android \
    --environment dev --audience tester --dry-run
  ./build.sh store --platform ios --confirm-store --dry-run

Dùng `derry ls -d` và đọc docs/guides/use-derry-and-build.md để xem workflow.
Các flag CLI cũ vẫn được hỗ trợ tạm thời nhưng đã deprecated.
EOF
}

fail() {
  echo "Lỗi: $*" >&2
  exit 1
}

warn() {
  echo "Cảnh báo: $*" >&2
}

require_value() {
  local option="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || fail "Thiếu giá trị cho $option."
}

validate_platform() {
  case "$platform" in
    android | ios | all) ;;
    *) fail "Platform phải là android, ios hoặc all." ;;
  esac
}

validate_environment() {
  case "$environment" in
    dev | staging | prod) ;;
    *) fail "Environment phải là dev, staging hoặc prod." ;;
  esac
}

validate_audience() {
  case "$audience" in
    tester | client) ;;
    *) fail "Audience phải là tester hoặc client." ;;
  esac
}

lane_for_environment() {
  case "$1" in
    dev) echo "build_dev_debug" ;;
    staging) echo "build_staging_staging" ;;
    prod) echo "build_prod_release" ;;
    *) fail "Không tìm thấy Fastlane lane cho environment '$1'." ;;
  esac
}

print_command() {
  local working_directory="$1"
  shift

  printf '(cd %q && ' "$working_directory"
  printf '%q ' "$@"
  printf ')\n'
}

ensure_fastlane_ready() {
  local target_platform="$1"
  local platform_root="$project_root/$target_platform"

  [[ -f "$platform_root/Gemfile" ]] ||
    fail "Không tìm thấy $target_platform/Gemfile."

  if [[ "$dry_run" == false ]]; then
    command -v bundle >/dev/null 2>&1 ||
      fail "Chưa có Bundler. Cài Ruby/Bundler rồi chạy bundle install trong $target_platform/."
    (
      cd "$platform_root"
      bundle check >/dev/null
    ) || fail "Gem chưa đủ cho $target_platform. Chạy (cd $target_platform && bundle install)."
  fi
}

run_fastlane() {
  local target_platform="$1"
  local lane="$2"
  local tester_groups="${3:-}"
  local platform_root="$project_root/$target_platform"
  local command=(bundle exec fastlane "$lane")

  if [[ -n "$tester_groups" ]]; then
    command+=("tester_groups:$tester_groups")
  fi
  if [[ "$push_tag" == true ]]; then
    command+=("push_tag:true")
  fi

  ensure_fastlane_ready "$target_platform"

  if [[ "$dry_run" == true ]]; then
    print_command "$platform_root" "${command[@]}"
    return
  fi

  (
    cd "$platform_root"
    if [[ -n "$tester_groups" ]]; then
      TESTER_GROUPS="$tester_groups" "${command[@]}"
    else
      "${command[@]}"
    fi
  )
}

run_distribution_for_platform() {
  local target_platform="$1"
  local lane
  local tester_groups="$audience-$target_platform"

  lane="$(lane_for_environment "$environment")"
  echo "Phân phối: platform=$target_platform environment=$environment audience=$audience group=$tester_groups"
  run_fastlane "$target_platform" "$lane" "$tester_groups"
}

run_distribution() {
  validate_platform
  validate_environment
  validate_audience

  case "$platform" in
    android | ios) run_distribution_for_platform "$platform" ;;
    all)
      run_distribution_for_platform android
      run_distribution_for_platform ios
      ;;
  esac
}

run_store_for_platform() {
  local target_platform="$1"

  echo "Release Store: platform=$target_platform"
  run_fastlane "$target_platform" build_store
}

run_store() {
  validate_platform
  if [[ "$confirm_store" != true ]]; then
    fail "Store upload cần xác nhận tường minh bằng --confirm-store."
  fi

  case "$platform" in
    android | ios) run_store_for_platform "$platform" ;;
    all)
      run_store_for_platform android
      run_store_for_platform ios
      ;;
  esac
}

parse_named_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --platform)
        require_value "$1" "${2:-}"
        platform="$2"
        shift 2
        ;;
      --environment)
        require_value "$1" "${2:-}"
        environment="$2"
        shift 2
        ;;
      --audience)
        require_value "$1" "${2:-}"
        audience="$2"
        shift 2
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --push-tag)
        push_tag=true
        shift
        ;;
      --confirm-store)
        confirm_store=true
        shift
        ;;
      -h | --help)
        print_usage
        exit 0
        ;;
      *) fail "Option không được hỗ trợ: $1" ;;
    esac
  done
}

parse_legacy_common_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tester) audience="tester" ;;
      --client) audience="client" ;;
      --dry-run) dry_run=true ;;
      --push-tag) push_tag=true ;;
      --confirm-store) confirm_store=true ;;
      *) fail "Option legacy không được hỗ trợ: $1" ;;
    esac
    shift
  done
}

run_legacy_distribution_batch() {
  local target_platform="$1"
  local target_environment

  platform="$target_platform"
  for target_environment in dev staging prod; do
    environment="$target_environment"
    run_distribution
  done
}

run_legacy() {
  local selector="$1"
  shift

  warn "CLI build.sh dạng '$selector' đã deprecated; hãy dùng derry hoặc named options."
  parse_legacy_common_options "$@"

  case "$selector" in
    --android) run_legacy_distribution_batch android ;;
    --ios) run_legacy_distribution_batch ios ;;
    --dev-debug-android)
      platform="android"
      environment="dev"
      run_distribution
      ;;
    --staging-staging-android)
      platform="android"
      environment="staging"
      run_distribution
      ;;
    --prod-release-android)
      platform="android"
      environment="prod"
      run_distribution
      ;;
    --dev-debug-ios)
      platform="ios"
      environment="dev"
      run_distribution
      ;;
    --staging-staging-ios)
      platform="ios"
      environment="staging"
      run_distribution
      ;;
    --prod-release-ios)
      platform="ios"
      environment="prod"
      run_distribution
      ;;
    --dev-debug)
      platform="all"
      environment="dev"
      run_distribution
      ;;
    --staging-staging)
      platform="all"
      environment="staging"
      run_distribution
      ;;
    --prod-release)
      platform="all"
      environment="prod"
      run_distribution
      ;;
    --store-android)
      platform="android"
      run_store
      ;;
    --store-ios)
      platform="ios"
      run_store
      ;;
    --store)
      platform="all"
      run_store
      ;;
    *) fail "Flag legacy không được hỗ trợ: $selector" ;;
  esac
}

main() {
  local command="${1:-}"

  case "$command" in
    "" | -h | --help)
      print_usage
      ;;
    distribute)
      shift
      parse_named_options "$@"
      run_distribution
      ;;
    store)
      shift
      parse_named_options "$@"
      run_store
      ;;
    --*) run_legacy "$@" ;;
    *)
      print_usage
      fail "Command không được hỗ trợ: $command"
      ;;
  esac
}

main "$@"
