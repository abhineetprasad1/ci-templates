# CI/CD Setup Guide — abhineetprasad1/ci-templates

## Repository layout

```
ci-templates/
├── .github/workflows/
│   ├── unity-mobile.yml        ← reusable: Android + iOS combined
│   ├── unity-android.yml       ← reusable: Android only
│   └── unity-ios.yml           ← reusable: iOS only
├── ci-support/
│   ├── Gemfile                 ← Fastlane gem dependencies
│   └── fastlane/
│       ├── Fastfile            ← lanes: ios upload, android upload
│       ├── Matchfile           ← Match defaults (overridden by env vars)
│       └── Appfile             ← App defaults (overridden by env vars)
├── scripts/
│   ├── build-number.sh         ← version/build-number computation
│   ├── activate-license.sh     ← manual license activation helper
│   └── return-license.sh       ← manual license return helper
└── example-game-repo/
    └── .github/workflows/ci.yml  ← template to copy into game repos
```

---

## 1. One-time repository setup

### 1a. Push this repo to GitHub

```bash
cd ci-templates
git init
git remote add origin git@github.com:abhineetprasad1/ci-templates.git
git add .
git commit -m "chore: initial ci-templates"
git push -u origin main
```

### 1b. Create a Fastlane Match certificates repo

Match stores encrypted signing certificates in a private git repo.

```bash
# Create a new private repo (e.g. abhineetprasad1/certs) then:
bundle exec fastlane match init
# → storage_mode: git
# → URL: git@github.com:abhineetprasad1/certs.git
```

Run once per game to create/register App ID and certificates:

```bash
MATCH_REPOSITORY=git@github.com:abhineetprasad1/certs.git \
IOS_BUNDLE_ID=com.dastangames.mygame \
IOS_TEAM_ID=ABCDE12345 \
bundle exec fastlane match appstore
```

---

## 2. Self-hosted macOS runner (iOS builds)

iOS builds must run on macOS due to Xcode requirements.

### Prerequisites on the runner machine

| Tool | Install |
|------|---------|
| Xcode (latest stable) | Mac App Store / xcode-select |
| Unity (version matching your project) | Unity Hub |
| Homebrew | https://brew.sh |
| Ruby ≥ 3.2 | `brew install ruby` |
| Bundler | `gem install bundler` |

### Register the runner

In GitHub: **Settings → Actions → Runners → New self-hosted runner**

```bash
# On the Mac
mkdir actions-runner && cd actions-runner
# Download and configure per the GitHub UI instructions, then:
./run.sh   # or install as a service: ./svc.sh install && ./svc.sh start
```

Label the runner `macOS` to match the workflow's `runs-on: [self-hosted, macOS]`.

---

## 3. GitHub Secrets

Add these in each game repo under **Settings → Secrets and variables → Actions**.

### Unity License

| Secret | Value |
|--------|-------|
| `UNITY_LICENSE` | Contents of your `.ulf` file (recommended) |

**Getting a .ulf file:**
```bash
# GameCI provides an action for this; run once on any machine with Unity:
# https://game.ci/docs/github/activation
```

Alternatively for Pro/Plus:

| Secret | Value |
|--------|-------|
| `UNITY_EMAIL` | Unity account email |
| `UNITY_PASSWORD` | Unity account password |
| `UNITY_SERIAL` | `XX-XXXX-XXXX-XXXX-XXXX-XXXX` |

### Android Signing

```bash
# Encode your keystore
base64 -i release.keystore | pbcopy
```

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.keystore` file |
| `ANDROID_KEYSTORE_PASS` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASS` | Key password |

### Google Play

1. Create a service account: Google Play Console → Setup → API access
2. Grant the service account **Release Manager** role
3. Download the JSON key

| Secret | Value |
|--------|-------|
| `GOOGLE_PLAY_JSON_KEY` | Full contents of the service account JSON file |

### App Store Connect (API Key)

1. App Store Connect → Users and Access → Integrations → App Store Connect API
2. Create a key with **App Manager** role
3. Download the `.p8` file (only downloadable once)

```bash
# Encode the .p8
base64 -i AuthKey_XXXXXXXX.p8 | pbcopy
```

| Secret | Value |
|--------|-------|
| `ASC_KEY_ID` | Key ID (10-char, e.g. `ABCDE12345`) |
| `ASC_ISSUER_ID` | Issuer UUID from the API Keys page |
| `ASC_KEY_CONTENT` | Base64-encoded `.p8` file contents |

### Fastlane Match

```bash
# Base64-encode: username:personal_access_token
echo -n "abhineetprasad1:ghp_xxx..." | base64 | pbcopy
```

| Secret | Value |
|--------|-------|
| `MATCH_PASSWORD` | Passphrase used when `match init` was run |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 `username:token` for the certs repo |
| `MATCH_REPOSITORY` | HTTPS or SSH URL of the certs repo |

---

## 4. Add CI to a game repo

1. Copy `example-game-repo/.github/workflows/ci.yml` into your game repo at `.github/workflows/ci.yml`
2. Update:
   - `unity_version` → your project's Unity editor version
   - `android_package_name` → your Android app ID
   - `ios_bundle_id` → your iOS bundle ID
   - `ios_team_id` → your Apple Team ID
3. Add all required secrets (see section 3)
4. Push to `main` or a `release/*` branch

---

## 5. Versioning strategy

| Trigger | `BUILD_VERSION` | `BUILD_NUMBER` |
|---------|----------------|----------------|
| Push with tag `v1.2.3` | `1.2.3` | `GITHUB_RUN_NUMBER` |
| Push without tag | `0.1.0` | `GITHUB_RUN_NUMBER` |

To cut a versioned release:
```bash
git tag v1.2.3
git push origin v1.2.3
```

---

## 6. Selecting Google Play track

The `google_play_track` input accepts: `internal`, `alpha`, `beta`, `production`.

- Default is `internal` for safety.
- Promote builds through tracks in the Google Play Console.
- Set `release_status: "completed"` in the Fastfile `supply` call to publish immediately (not recommended for production without review).

---

## 7. Troubleshooting

**License activation fails**
- Ensure `UNITY_LICENSE` secret contains the full `.ulf` XML, not just a path.
- For Professional licenses, verify the serial is not already activated on another machine; return it first.

**Match certificate errors in CI**
- `readonly: true` is set for CI runs — certificates must already exist in the Match repo.
- Run `fastlane match appstore` locally once to seed the repo.

**AAB not found by Fastlane Supply**
- GameCI outputs to `build/Android/<BuildName>/<BuildName>.aab`.
- The `AAB_PATH` env var points to `build/Android`; Fastfile uses `Dir.glob` to find it recursively.

**iOS build fails with "No Unity installation found"**
- Ensure Unity is installed via Unity Hub on the self-hosted runner.
- The path must match what GameCI expects. Set `UNITY_PATH` if needed.
