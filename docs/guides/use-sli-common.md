# Use `sli_common`

The app consumes `sli_common` through the Git submodule at
`lib/modules/sli_common` and a path dependency in `pubspec.yaml`.

## Consume

```dart
import 'package:sli_common/sli_common.dart';

SliButton(
  label: 'Save',
  onPressed: onSave,
)
```

Prefer semantic `Sli*` components and tokens. Import selected symbols with
`show` when it improves dependency clarity. Do not import `lib/src/...` or use
direct `shadcn_flutter` APIs in application screens.

## Contribute

Make a shared abstraction only when it is reusable across products. Work and
verify inside the standalone `sli_common` repository first:

```bash
cd lib/modules/sli_common
flutter analyze lib/src test example/lib
flutter test
```

Commit and push the package change, then return to the base and commit the new
submodule pointer. Document breaking changes and migration in the toolkit's
CHANGELOG and docs.

Product-specific copy, routes, Cubits/BLoCs, APIs, and business behavior remain
in the application even when they visually compose shared components.
