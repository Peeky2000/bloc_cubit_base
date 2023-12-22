#!/bin/bash

case $1 in
--assets-models)
  fvm flutter pub get
  fvm flutter pub run build_runner build --delete-conflicting-outputs
  ;;
--localize)
  fvm flutter gen-l10n
  cd lib/modules/sli_common
  fvm flutter gen-l10n
  ;;
--app-icon)
  fvm flutter pub get
  fvm flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons*
  ;;
--splash-screen)
  fvm flutter pub get
  fvm flutter pub run flutter_native_splash:create --flavor dev
  fvm flutter pub run flutter_native_splash:create --flavor staging
  fvm flutter pub run flutter_native_splash:create --flavor prod
  ;;
*)
  echo "┌────────────────────────────────────────┐"
  echo "│               Generation               │"
  echo "├────────────────────────────────────────┤"
  echo "│1.  --assets-models                     │"
  echo "│2.  --localize                          │"
  echo "│3.  --app-icon                          │"
  echo "│4.  --splash-screen                     │"
  echo "│Or Please read README to learn more.    │"
  echo "└────────────────────────────────────────┘"
  ;;
esac
