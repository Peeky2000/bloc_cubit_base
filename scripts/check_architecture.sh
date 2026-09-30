#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

failed=0

if rg -n "package:bloc_cubit_base/(data|presentation)/" lib/domain --glob '*.dart'; then
  echo "Domain must not import data or presentation layers." >&2
  failed=1
fi

if rg -n "package:bloc_cubit_base/data/" lib/presentation --glob '*.dart'; then
  echo "Presentation must not import the data layer." >&2
  failed=1
fi

if rg -n "Injector\.getIt|GetIt\.instance" lib/domain lib/data \
  lib/presentation --glob '*_cubit.dart' --glob '*_bloc.dart'; then
  echo "Feature layers must use constructor injection instead of the service locator." >&2
  failed=1
fi

if rg -n \
  "package:flutter/|/l10n/|core/routing/|core/widget/|app_controller\.dart|presentation/global_handler\.dart|BuildContext|SLIRouting|DialogUtil" \
  lib/presentation --glob '**/cubit/*.dart'; then
  echo "Cubit/BLoC files must not depend on UI, routing, localization, or BuildContext." >&2
  failed=1
fi

exit "$failed"
