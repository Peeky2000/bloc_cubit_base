# Organism Catalog

Organisms live in `lib/shared/widgets/organisms/`. Always check here before creating a new widget.

All organisms receive data and callbacks through their constructor.
None of them call BLoC or Repository directly.

---

## Auth

| Widget | Does | Receives from outside |
|---|---|---|
| `LoginForm` | Email + password + submit button + forgot password link | `onSubmit(email, password)`, `isLoading`, `errorMessage` |
| `RegisterForm` | Full name + email + password + confirm + submit | `onSubmit(...)`, `isLoading`, `errorMessage` |
| `OtpVerifyForm` | OTP input + countdown + resend | `onSubmit(otp)`, `onResend()`, `isLoading`, `expiresIn` |
| `SocialLoginGroup` | Google / Apple / Facebook login buttons | `onGoogleTap`, `onAppleTap`, `onFacebookTap` |

---

## User / Profile

| Widget | Does | Receives from outside |
|---|---|---|
| `ProfileHeader` | Large avatar + name + subtitle + edit button | `user`, `onEditTap` |
| `ProfileStatRow` | Stats row (posts / followers / following) | `stats` (List\<label-value\>) |
| `ProfileMenuList` | Settings rows with icons | `items`, `onTap` |
| `AvatarUploadCard` | Avatar + camera overlay + upload progress | `url`, `onPickImage`, `uploadProgress` |

---

## Product

| Widget | Does | Receives from outside |
|---|---|---|
| `ProductCard` | Image + name + price + rating + add-to-cart button | `product`, `onAddToCart`, `onTap` |
| `ProductDetailHeader` | Image gallery + name + price + badge | `product`, `onImageTap` |
| `ProductDetailInfo` | Description + specs + rating summary | `product` |
| `ProductFilterBar` | Horizontally scrollable filter chips | `filters`, `selectedFilters`, `onFilterTap` |
| `ProductGrid` | Grid layout of multiple `ProductCard` | `products`, `onProductTap`, `onAddToCart` |
| `ProductListItem` | Single product row (list view layout) | `product`, `onTap`, `onAddToCart` |

---

## Cart / Order

| Widget | Does | Receives from outside |
|---|---|---|
| `CartItem` | Image + name + price + quantity stepper + remove | `item`, `onQuantityChange`, `onRemove` |
| `CartSummary` | Subtotal + shipping + discount + total | `summary` |
| `OrderStatusStepper` | Order steps with current step highlighted | `steps`, `currentStep` |
| `OrderHistoryItem` | Order ID + date + status + total | `order`, `onTap` |
| `VoucherInputRow` | Voucher code input + apply button + result display | `onApply(code)`, `appliedVoucher`, `isLoading` |

---

## Form Blocks

| Widget | Does | Receives from outside |
|---|---|---|
| `AddressForm` | Full address form (province / district / ward + street) | `initialValue`, `onChanged` |
| `PaymentMethodSelector` | Selectable list of payment methods | `methods`, `selected`, `onSelect` |
| `QuantityStepper` | Increment / decrement with min/max bounds | `value`, `min`, `max`, `onChanged` |

---

## Feedback / Empty States

| Widget | Does | Receives from outside |
|---|---|---|
| `EmptyState` | Lottie/image + title + subtitle + CTA button | `title`, `subtitle`, `animation`, `onAction`, `actionLabel` |
| `ErrorState` | Error icon + message + retry button | `message`, `onRetry` |
| `SkeletonList` | List of skeleton rows while loading | `itemCount`, `itemHeight` |
| `SkeletonCard` | Card skeleton while loading | `width`, `height` |
| `ConfirmDialog` | Confirmation dialog with two buttons | `title`, `message`, `onConfirm`, `onCancel`, `confirmLabel` |
| `BottomSheetHandle` | Drag handle + title for bottom sheets | `title`, `onClose` |

---

## Navigation

| Widget | Does | Receives from outside |
|---|---|---|
| `AppNavBar` | Bottom navigation with notification badges | `currentIndex`, `onTap`, `items` |
| `AppTopBar` | Normalised AppBar: title + back + actions | `title`, `showBack`, `actions`, `onBackTap` |
| `SliverAppHeader` | Collapsible AppBar for detail pages | `title`, `backgroundImage`, `actions` |
| `TabBarSection` | Tab bar + TabBarView combined | `tabs`, `children` |
