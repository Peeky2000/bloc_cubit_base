# Translation files (JSON)

## File structure

Use nested JSON to group keys by feature. Keys follow the `feature.subkey` pattern.

```
assets/translations/
  vi.json
  en.json
```

### vi.json

```json
{
  "common": {
    "confirm": "Xác nhận",
    "cancel": "Hủy",
    "save": "Lưu",
    "delete": "Xóa",
    "loading": "Đang tải..."
  },
  "auth": {
    "login": "Đăng nhập",
    "logout": "Đăng xuất",
    "email": "Email",
    "password": "Mật khẩu",
    "welcome": "Xin chào, {}!"
  },
  "product": {
    "title": "Sản phẩm",
    "count": "{} sản phẩm",
    "empty": "Không có sản phẩm nào"
  },
  "error": {
    "network": "Lỗi kết nối mạng",
    "unknown": "Đã có lỗi xảy ra"
  }
}
```

### en.json

```json
{
  "common": {
    "confirm": "Confirm",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "loading": "Loading..."
  },
  "auth": {
    "login": "Login",
    "logout": "Logout",
    "email": "Email",
    "password": "Password",
    "welcome": "Hello, {}!"
  },
  "product": {
    "title": "Products",
    "count": "{} products",
    "empty": "No products found"
  },
  "error": {
    "network": "Network error",
    "unknown": "Something went wrong"
  }
}
```

## Naming conventions

| Pattern | Example key | When to use |
|---|---|---|
| `feature.action` | `auth.login` | buttons, labels |
| `feature.noun` | `product.title` | screen titles |
| `feature.state` | `product.empty` | empty states |
| `common.xxx` | `common.confirm` | shared across features |
| `error.xxx` | `error.network` | error messages |

## Plural keys

```json
{
  "cart": {
    "item_count": {
      "zero": "Cart is empty",
      "one": "{} item",
      "other": "{} items"
    }
  }
}
```
