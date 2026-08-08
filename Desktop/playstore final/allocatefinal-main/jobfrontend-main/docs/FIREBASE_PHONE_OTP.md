# Fix Firebase OTP opening a browser (reCAPTCHA)

Firebase Phone Auth opens a browser/captcha when it **cannot silently verify** your Android app. That is almost always missing **SHA-1 / SHA-256** fingerprints in the Firebase project.

Package: `com.joballocate.careers`  
Firebase project: `joballocate`

## Your DEBUG fingerprints (this machine)

Run:

```powershell
powershell -File jobfrontend-main/scripts/print_android_sha.ps1
```

Current debug keystore on this PC:

- **SHA-1:** `94:60:5C:91:74:9D:BC:85:70:91:50:09:65:85:56:1E:D9:C4:96:44`
- **SHA-256:** `BA:5B:D3:6A:5F:D1:CC:E9:41:44:72:AF:DC:B2:B0:21:0E:18:64:A3:CD:51:57:AA:BC:FF:52:8F:76:B0:CD:7D`

These were **not** in `google-services.json` (only other release/upload hashes were registered), so debug builds fall back to browser captcha.

## Steps (required — Console only)

1. Open [Firebase Console](https://console.firebase.google.com/) → project **joballocate**
2. Project settings (gear) → **Your apps** → Android app `com.joballocate.careers`
3. **Add fingerprint** → paste **SHA-1**, save
4. **Add fingerprint** again → paste **SHA-256**, save
5. If you ship release/Play builds: also add SHA-1 + SHA-256 from:
   - your release keystore (`print_android_sha.ps1`), **and**
   - Play Console → App signing → **App signing key certificate** (if Play App Signing is on)
6. Download a fresh `google-services.json` → replace `android/app/google-services.json`
7. Google Cloud Console → same project → enable **Play Integrity API**
8. Rebuild the app (`flutter clean` then `flutter run`)

After this, OTP should send **inside the app** (SMS) without opening a browser.

## Notes

- This cannot be fixed by Flutter code alone — Firebase must trust the signing certificate.
- iOS uses APNs silent push instead of SHA; different setup if iOS also shows issues.
- Test phone numbers in Firebase Auth can skip SMS for internal testing, but real devices still need SHA for silent verification.
