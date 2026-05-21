# Hướng dẫn tích hợp Firebase Auth (Google Sign-In + Email/Password)

## Các file đã thêm / chỉnh sửa

| File | Trạng thái | Mô tả |
|------|-----------|-------|
| `lib/services/auth_service.dart` | **MỚI** | Service xử lý toàn bộ Firebase Auth |
| `lib/screens/login_screen.dart` | **MỚI** | Màn hình đăng nhập / đăng ký |
| `lib/screens/auth_wrapper.dart` | **MỚI** | Điều hướng tự động theo trạng thái auth |
| `lib/screens/user_screen.dart` | **CẬP NHẬT** | Hiển thị thông tin user + đăng xuất |
| `lib/main.dart` | **CẬP NHẬT** | Dùng `AuthWrapper` làm màn hình gốc |
| `pubspec.yaml` | **CẬP NHẬT** | Thêm `firebase_auth` và `google_sign_in` |

---

## Bước 1 — Cài đặt packages

```bash
flutter pub get
```

---

## Bước 2 — Bật Firebase Authentication trên Console

1. Vào [Firebase Console](https://console.firebase.google.com) → project `inventory-manager-d70ea`
2. Chọn **Authentication** → **Sign-in method**
3. Bật **Email/Password**
4. Bật **Google** (chọn email hỗ trợ dự án)

---

## Bước 3 — Cấu hình Google Sign-In cho Android

### 3a. Lấy SHA-1 fingerprint

```bash
# Debug keystore (Windows)
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Debug keystore (Mac/Linux)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 3b. Thêm SHA-1 vào Firebase

1. Firebase Console → **Project settings** (biểu tượng bánh răng)
2. Chọn app Android → **Add fingerprint** → dán SHA-1
3. Tải lại file `google-services.json` mới → thay vào `android/app/google-services.json`

---

## Bước 4 — Cấu hình Google Sign-In cho iOS

1. Trong Firebase Console → **Project settings** → chọn app iOS
2. Tải file `GoogleService-Info.plist` → thay vào `ios/Runner/GoogleService-Info.plist`
3. Mở `ios/Runner/Info.plist`, thêm URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Lấy REVERSED_CLIENT_ID từ GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.762221062157-XXXXXXXXXXXXXXXX</string>
    </array>
  </dict>
</array>
```

---

## Bước 5 — Kiểm tra android/app/build.gradle.kts

Đảm bảo `minSdk >= 23` (Google Sign-In yêu cầu):

```kotlin
android {
    defaultConfig {
        minSdk = 23   // tối thiểu 23
    }
}
```

---

## Chức năng đã tích hợp

### Đăng nhập
- Email + mật khẩu với validation đầy đủ
- Google Sign-In (one-tap)
- Quên mật khẩu → gửi email reset

### Đăng ký
- Tên hiển thị + Email + Mật khẩu + Xác nhận mật khẩu
- Kiểm tra định dạng email
- Mật khẩu tối thiểu 6 ký tự

### Quản lý phiên
- `AuthWrapper` tự động điều hướng:
  - Chưa đăng nhập → `LoginScreen`
  - Đã đăng nhập → `HomeScreen`
- Đăng xuất từ `UserScreen` (có confirm dialog)

### Thông báo lỗi tiếng Việt
Tất cả lỗi Firebase được dịch sang tiếng Việt trong `AuthService.getErrorMessage()`.

---

## Lưu ý bảo mật

- Không commit `google-services.json` lên git public (đã có trong `.gitignore`)
- Cần cấu hình **Firestore Rules** để phân quyền theo `uid` người dùng
- Đối với production: bật **Play Integrity** thay vì `debug` trong `AndroidProvider`
