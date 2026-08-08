# Firebase service account for FCM push (local / server only — not in git)

1. Download from Firebase Console → Project settings → Service accounts → Generate new private key
2. Save as e.g. `joballocate-firebase-adminsdk-….json` in this folder
3. Upload the same file to the live server at:

`backend/storage/app/firebase/`

Do not commit `*.json` here — GitHub blocks service-account secrets.
