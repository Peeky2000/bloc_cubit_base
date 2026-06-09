# Molecule Catalog

Molecules live in `lib/shared/widgets/molecules/`. Always check here before creating a new widget.

---

## User

| Widget | Composed of | Does |
|---|---|---|
| `UserAvatarInfo` | `AppAvatar` + `AppText` ×2 | Avatar + name + subtitle (email/role) in a horizontal row |
| `UserAvatarStack` | `AppAvatar` ×n | Overlapping avatars with "+N" overflow label |

---

## Product

| Widget | Composed of | Does |
|---|---|---|
| `ProductThumbnail` | `AppImage` + `AppLabel` + `AppText` | Image + name + price in a small card layout |
| `ProductPriceLine` | `AppText` ×2 + `AppLabel` | Strikethrough original price + sale price + "% off" badge |
| `ProductRatingRow` | `AppRating` + `AppText` | Stars + review count |

---

## Form

| Widget | Composed of | Does |
|---|---|---|
| `LabeledField` | `AppText` + `AppTextField` | Label above + input below, normalised spacing |
| `PasswordField` | `AppTextField` + `AppIconButton` | Password input + show/hide toggle — manages `obscureText` state internally |
| `SearchBar` | `AppSearchField` + `AppIconButton` | Search input + filter or voice button |
| `FormErrorMessage` | `AppIcon` + `AppText` | Warning icon + error text for form-level errors (not field-level) |

**`PasswordField` note:** one of the rare molecules that holds state — only because `obscureText` is pure UI state with zero business logic.

---

## Feedback

| Widget | Composed of | Does |
|---|---|---|
| `ToastMessage` | `AppIcon` + `AppText` | Content block shown inside a toast (success/error/warning/info) |
| `InlineAlert` | `AppIcon` + `AppText` + `AppTextButton` | Inline warning banner with an action button |
| `LoadingDots` | `AppSkeleton` ×3 | Three animated dots — typing indicator |

---

## List Items

| Widget | Composed of | Does |
|---|---|---|
| `ListTileBasic` | `AppIcon` + `AppText` ×2 | Leading icon + title + subtitle — settings-style row |
| `ListTileAvatar` | `AppAvatar` + `AppText` ×2 + `AppIcon` | Avatar + title + subtitle + trailing icon |
| `ListTileProduct` | `AppImage` + `AppText` ×2 + `AppBadge` | Thumbnail + name + price + badge |
| `SelectableTile` | `ListTileBasic` + `AppCheckbox` | Selectable row for multi-select lists |

---

## Navigation

| Widget | Composed of | Does |
|---|---|---|
| `BottomNavItem` | `AppSvgIcon` + `AppText` + `AppBadge` | Single bottom nav tab: icon + label + notification badge |
| `BreadcrumbItem` | `AppText` + `AppIcon` | One breadcrumb segment + separator |
| `TabItem` | `AppText` + `AppStatusDot` | Tab label + active-state dot |
