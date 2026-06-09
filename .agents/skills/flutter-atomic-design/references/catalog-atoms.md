# Atom Catalog

Atoms live in `lib/shared/widgets/atoms/`. Always check here before creating a new widget.

---

## Typography

| Widget | Does | Key props |
|---|---|---|
| `AppText` | Normalises typography — maps `variant` → `TextStyle` from `AppTypography` | `text`, `variant` (title/body/caption/…), `color`, `maxLines` |
| `AppLabel` | Small badge/tag text, usually with a background | `text`, `color`, `backgroundColor` |
| `AppRichText` | Multi-style text in one line | `spans` (List\<TextSpan\>) |

---

## Media

| Widget | Does | Key props |
|---|---|---|
| `AppImage` | Wraps `CachedNetworkImage` — loading placeholder + error fallback | `url`, `width`, `height`, `fit`, `borderRadius` |
| `AppAvatar` | Circular image with initial-letter fallback when URL is null or fails | `url`, `name`, `size`, `border` |
| `AppSvgIcon` | Renders SVG asset, normalises size and color | `assetPath`, `size`, `color` |
| `AppIcon` | Wraps `Icon` — normalises size via sm/md/lg enum | `icon`, `size`, `color` |
| `AppLottie` | Lottie animation for empty states, loading, success | `assetPath`, `width`, `height`, `repeat` |

---

## Buttons

| Widget | Does | Key props |
|---|---|---|
| `AppButton` | Primary CTA — primary / secondary / outline / text variants | `label`, `onPressed`, `variant`, `isLoading`, `isDisabled`, `icon` |
| `AppIconButton` | Icon-only button | `icon`, `onPressed`, `size`, `tooltip` |
| `AppTextButton` | Text button without border or background | `label`, `onPressed`, `color` |
| `AppFloatingButton` | Wraps FAB, normalises icon and elevation | `icon`, `onPressed`, `label` |

**`AppButton` built-in behaviour:** when `isLoading = true` → hides label, shows small `CircularProgressIndicator`, disables `onPressed` automatically.

---

## Form Inputs

| Widget | Does | Key props |
|---|---|---|
| `AppTextField` | Standard text input — style, border, label, error message | `label`, `hint`, `controller`, `errorText`, `onChanged`, `inputType`, `obscureText` |
| `AppSearchField` | TextField + search icon + clear button | `hint`, `onChanged`, `onClear`, `autofocus` |
| `AppDropdown<T>` | Type-safe dropdown select | `label`, `items`, `value`, `onChanged`, `itemBuilder` |
| `AppCheckbox` | Checkbox with label, normalised spacing | `label`, `value`, `onChanged` |
| `AppRadio<T>` | Radio button with label | `label`, `value`, `groupValue`, `onChanged` |
| `AppSwitch` | Toggle switch with label | `label`, `value`, `onChanged` |
| `AppDatePicker` | Triggers date picker dialog, displays selected value | `label`, `value`, `onChanged`, `firstDate`, `lastDate` |
| `AppOtpField` | Multi-box OTP input with auto-focus jump | `length`, `onCompleted`, `onChanged` |

**`AppTextField` built-in behaviour:** renders `errorText` below field with correct style; toggles show/hide password when `obscureText = true`; does NOT manage `TextEditingController` itself.

---

## Display

| Widget | Does | Key props |
|---|---|---|
| `AppBadge` | Notification count badge — hides when count = 0, shows "99+" above max | `count`, `child`, `maxCount` |
| `AppChip` | Selectable or deletable tag | `label`, `isSelected`, `onTap`, `onDelete`, `color` |
| `AppDivider` | Horizontal or vertical divider — normalised color and spacing | `direction`, `color`, `thickness`, `indent` |
| `AppSkeleton` | Rectangle or circle loading placeholder | `width`, `height`, `borderRadius`, `isCircle` |
| `AppStatusDot` | Coloured dot indicating status (online/offline/pending) | `status`, `size` |
| `AppProgressBar` | Linear progress bar | `value` (0.0–1.0), `color`, `backgroundColor`, `height` |
| `AppRating` | Star rating — read-only or interactive | `value`, `maxValue`, `onChanged`, `size` |
