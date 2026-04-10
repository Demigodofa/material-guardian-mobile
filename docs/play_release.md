# Play Release Notes

Material Guardian Flutter supports release signing through either:

- environment variables: `MG_STORE_FILE`, `MG_STORE_PASSWORD`, `MG_KEY_ALIAS`, `MG_KEY_PASSWORD`
- a local repo file: `release-signing.properties`

Do not commit real signing material. The repo ignores:

- `release-signing.properties`
- `keystore/`

Recommended flow:

1. Copy `release-signing.sample.properties` to `release-signing.properties`.
2. Create an upload keystore, for example:

```powershell
keytool -genkeypair -v -keystore keystore\material-guardian-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

3. Fill in the real values in `release-signing.properties`.
4. Build the Play bundle.

Internal validation can still target the live dev backend if that is the environment being exercised.
Do not ship a customer-facing Play release against the default `...backend-dev...` URL by accident.
For any real release, pass the intended non-dev backend explicitly with `MG_BACKEND_BASE_URL`.

```powershell
& 'C:\Users\KevinPenfield\develop\flutter\bin\flutter.bat' build appbundle --release --dart-define=MG_BACKEND_BASE_URL=https://app-platforms-backend-dev-293518443128.us-east4.run.app
```

5. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

Release gate before customer rollout:

- Play Console service-account linkage is now working for `mg-play-verifier@asme-receiving.iam.gserviceaccount.com`.
- The critical remaining Google billing proof is a real purchase-token smoke, not the older `permissionDenied` API-access blocker.
- Durable operator note: the working Play Console fix was `API access` for the service account, not only the human-style `Users and permissions` invite flow.

Versioning and naming standard:

- `versionName` should use `major.minor.patch` with no `v` prefix, for example `1.0.2`.
- `versionCode` should increase on every Play-uploaded Android bundle.
- Play Console release names should use `major.minor.patch (build) - summary`, for example `1.0.2 (3) - Billing Test`.
- For internal-only releases, you may include the track for clarity: `1.0.2 (3) Internal - Billing Test`.

Current package target:

- release: `com.asme.receiving`
- debug: `com.asme.receiving.dev`
