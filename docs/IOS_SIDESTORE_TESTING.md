# Installing Pottery Manager on iPhone with SideStore

This is the free, per-device signing route for the three iPhone testers. The repository publishes an **unsigned, device-targeted iOS IPA** as a GitHub Actions artifact. Each tester installs and signs that same IPA on their own iPhone with their own Apple Account (Apple ID). The project does not need your Apple Developer account, certificates, or signing secrets.

## What each tester needs

- An iPhone running a SideStore-supported iOS version (currently iOS 15 or later).
- Their own Apple Account. A separate account per tester is fine; do not share passwords.
- A Windows 8+, macOS High Sierra+, or supported Linux computer for the initial SideStore installation and device pairing.
- A USB cable, Wi-Fi, and the **LocalDevVPN** app.
- Access to the PotteryTracker GitHub repository to download the IPA artifact.

SideStore is a community sideloading tool, not Apple's App Store. With a free Apple Account, SideStore documents a limit of three active sideloaded apps (including SideStore) and ten app IDs per week. Free provisioning lasts seven days, so the apps must be refreshed regularly. LocalDevVPN must be connected when installing, updating, or refreshing apps.

## 1. Install SideStore (each tester does this on their own device)

1. Follow the official [SideStore prerequisites](https://docs.sidestore.io/docs/installation/prerequisites) and install LocalDevVPN from the App Store.
2. On the computer, install and run the official **iloader** from the SideStore installation instructions.
3. Connect the iPhone by USB, unlock it, and choose **Trust This Computer** if prompted.
4. In iloader, select that iPhone, sign in using the tester's own Apple Account, and choose **Install SideStore (Stable)**.
5. On the iPhone, trust the developer profile under **Settings → General → VPN & Device Management**. Enable **Developer Mode** under **Settings → Privacy & Security** if iOS requests it, then restart.
6. Open LocalDevVPN and connect. Open SideStore and sign in with the same Apple Account used for that install.
7. In SideStore → **My Apps**, tap the **7 DAYS** counter beside SideStore to complete its first refresh. Accept any prompt to create or refresh a signing certificate.

The initial computer setup is per iPhone. Do not copy another tester's pairing file or Apple credentials. If pairing later expires, follow the official [pairing-file repair guide](https://docs.sidestore.io/docs/advanced/pairing-file).

## 2. Download the Pottery Manager IPA

1. Open the repository's [Actions page](https://github.com/mamefan1945/PotteryTracker/actions).
2. Open the latest successful **iOS CI** run on the `main` branch.
3. Under **Artifacts**, download **pottery-manager-ios-sidestore-ipa**.
4. Extract the downloaded artifact ZIP. Inside it is `pottery-manager-sidestore.ipa`.

The workflow compiles Flutter for the iPhoneOS device target (arm64), verifies the executable does not contain simulator architectures, packages it as `Payload/Runner.app`, and uploads the IPA. The IPA is intentionally unsigned; SideStore signs it on each tester's device.

## 3. Install the IPA (each tester)

1. Transfer `pottery-manager-sidestore.ipa` to the iPhone (Files/iCloud Drive, AirDrop, or another trusted transfer method).
2. Connect LocalDevVPN.
3. Open the IPA from the Files app and choose **Share → SideStore** (or import it from SideStore's **+** button / **My Apps** screen, depending on the SideStore version).
4. Confirm installation. SideStore signs the app using the Apple Account currently signed in to that tester's SideStore.
5. Launch **Pottery Manager** from the Home Screen.

Each tester signs independently. The same unsigned IPA can be used by all three; signing happens locally and each tester's free provisioning profile is separate.

## 4. Install future updates without losing app data

1. Download the new `pottery-manager-ios-sidestore-ipa` artifact from the latest successful iOS CI run.
2. Import the new IPA into the **existing SideStore installation** on that iPhone. Do not delete Pottery Manager first.
3. Confirm the update. Use the same Apple Account and keep the app's bundle identifier unchanged.
4. Launch the updated app and verify the existing studio records are present.

The workflow keeps the bundle identifier fixed at `com.mamefan1945.potterymanager`, keeps the marketing version at the version in `pubspec.yaml`, and increases the iOS build number on every GitHub Actions run. That combination allows iOS to recognize later builds as updates. App data is retained when updating in place; deleting the app first can remove its local data.

## 5. Keep the free signature valid

Free Apple Account signatures expire after seven days. Open SideStore with LocalDevVPN connected and refresh Pottery Manager before it expires. SideStore can refresh over Wi-Fi after the one-time computer setup; the computer is not normally needed for weekly refreshes. Keep SideStore itself refreshed too.

## Important limits and troubleshooting

- A free Apple Account can have only three active sideloaded apps at once, **including SideStore**. That leaves room for at most two other sideloaded apps on that device.
- Apple also limits free accounts to ten app IDs in a week. Repeatedly changing the app bundle ID consumes this allowance; this project keeps it stable.
- Each tester must use their own Apple Account in SideStore. Do not sign all three devices with one shared account.
- If installation or refresh fails, verify Wi-Fi and LocalDevVPN are connected, then consult the [SideStore troubleshooting guide](https://docs.sidestore.io/docs/troubleshooting).
- GitHub Actions artifacts are temporary downloads (configured for 30-day retention). Download and keep a copy of each IPA you distribute.

Official references: [SideStore install](https://docs.sidestore.io/docs/installation/install.html) · [Prerequisites](https://docs.sidestore.io/docs/installation/prerequisites) · [FAQ and free-account limits](https://docs.sidestore.io/docs/faq.html).
