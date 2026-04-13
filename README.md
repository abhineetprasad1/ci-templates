# ci-templates

Reusable GitHub Actions workflows for Unity mobile CI/CD (iOS + Android).
Built on [GameCI](https://game.ci) + [Fastlane](https://fastlane.tools).

## Repository layout

```
ci-templates/
├── .github/workflows/
│   ├── unity-mobile.yml        ← reusable: Android + iOS combined
│   ├── unity-android.yml       ← reusable: Android only
│   └── unity-ios.yml           ← reusable: iOS only
├── ci-support/
│   ├── Gemfile
│   └── fastlane/
│       ├── Fastfile            ← lanes: ios upload, android upload
│       ├── Matchfile
│       └── Appfile
├── scripts/
│   ├── build-number.sh
│   ├── activate-license.sh
│   └── return-license.sh
├── example-game-repo/
│   └── .github/workflows/ci.yml   ← copy this into each game repo
└── docs/
    └── setup.md                    ← extended reference (runner setup, troubleshooting)
```

---

## New game setup checklist

Follow these steps every time you add a new game.

### Step 1 — Create the app in the stores

**App Store Connect**
1. Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Apps → **+** → New App → set Bundle ID (e.g. `com.yourcompany.mygame`)
3. Note your **Team ID** from [developer.apple.com/account](https://developer.apple.com/account) → Membership

**Google Play Console**
1. Log in to [play.google.com/console](https://play.google.com/console)
2. **Create app** → set package name (e.g. `com.yourcompany.mygame`)
3. Upload a first manual AAB — Google requires this before API uploads work
4. Download the service account JSON key: Setup → API access → Service account → JSON key

---

### Step 2 — Generate iOS certificates with Fastlane Match

Run from the `ci-support/` directory of this repo:

```bash
cd ci-support

# App Store (TestFlight / production)
IOS_BUNDLE_ID=com.yourcompany.mygame \
IOS_TEAM_ID=YOURTEAMID \
MATCH_REPOSITORY=https://github.com/abhineetprasad1/certs \
bundle exec fastlane match appstore

# Development (optional, for local testing)
IOS_BUNDLE_ID=com.yourcompany.mygame \
IOS_TEAM_ID=YOURTEAMID \
MATCH_REPOSITORY=https://github.com/abhineetprasad1/certs \
bundle exec fastlane match development
```

You will be prompted for the Match passphrase. Use the same passphrase as all other games.

---

### Step 3 — Generate an Android keystore

```bash
keytool -genkey -v \
  -keystore mygame.keystore \
  -alias mygame \
  -keyalg RSA -keysize 2048 \
  -validity 10000

# Base64-encode it for the GitHub secret
base64 -i mygame.keystore | pbcopy
```

Store `mygame.keystore` somewhere safe (e.g. 1Password). You will need it if you ever re-sign manually.

---

### Step 4 — Get an App Store Connect API key

Skip this step if you already have an org-wide key stored in the shared secrets.

1. App Store Connect → Users and Access → Integrations → **App Store Connect API**
2. Create a key with **App Manager** role
3. Download the `.p8` file (only downloadable once — save it securely)
4. Note the **Key ID** and **Issuer ID**

```bash
# Base64-encode the .p8 for the GitHub secret
base64 -i AuthKey_XXXXXXXX.p8 | pbcopy
```

---

### Step 5 — Add GitHub secrets to the game repo

Go to: game repo → **Settings → Secrets and variables → Actions**

| Secret | How to get it |
|--------|---------------|
| `UNITY_LICENSE` | Contents of your `.ulf` file — see [GameCI activation](https://game.ci/docs/github/activation) |
| `ANDROID_KEYSTORE_BASE64` | Base64 keystore from Step 3 |
| `ANDROID_KEYSTORE_PASS` | Keystore password set in Step 3 |
| `ANDROID_KEY_ALIAS` | Key alias set in Step 3 (e.g. `mygame`) |
| `ANDROID_KEY_PASS` | Key password set in Step 3 |
| `GOOGLE_PLAY_JSON_KEY` | Full contents of the JSON key from Step 1 |
| `ASC_KEY_ID` | Key ID from Step 4 |
| `ASC_ISSUER_ID` | Issuer ID from Step 4 |
| `ASC_KEY_CONTENT` | Base64 `.p8` from Step 4 |
| `MATCH_PASSWORD` | Passphrase used when Match was initialised |
| `MATCH_GIT_BASIC_AUTHORIZATION` | See below |
| `MATCH_REPOSITORY` | `https://github.com/abhineetprasad1/certs` |

**Generating `MATCH_GIT_BASIC_AUTHORIZATION`:**

```bash
echo -n "abhineetprasad1:YOUR_GITHUB_PAT" | base64 | pbcopy
```

The PAT needs `repo` scope on the `certs` repository.

---

### Step 6 — Add the workflow to the game repo

```bash
mkdir -p .github/workflows
cp /path/to/ci-templates/example-game-repo/.github/workflows/ci.yml \
   .github/workflows/ci.yml
```

Edit the following values in `ci.yml`:

```yaml
unity_version:         "2022.3.20f1"            # your project's Unity version
android_package_name:  "com.yourcompany.mygame"
android_build_name:    "MyGame"
ios_bundle_id:         "com.yourcompany.mygame"
ios_team_id:           "YOURTEAMID"
ios_build_name:        "MyGame"
```

---

### Step 7 — Push and verify

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add mobile CI/CD pipeline"
git push origin main
```

Or trigger manually: **Actions → Mobile CI/CD → Run workflow**

Watch the run. A green build means everything is wired up correctly.

---

## Versioning

| Trigger | `BUILD_VERSION` | `BUILD_NUMBER` |
|---------|----------------|----------------|
| Tag `v1.2.3` | `1.2.3` | `GITHUB_RUN_NUMBER` |
| Push without tag | `0.1.0` | `GITHUB_RUN_NUMBER` |

To cut a versioned release:

```bash
git tag v1.2.3
git push origin v1.2.3
```

---

## Extended docs

See [`docs/setup.md`](docs/setup.md) for:
- Self-hosted macOS runner setup
- Detailed troubleshooting (license errors, Match issues, AAB not found)
- Google Play track selection
