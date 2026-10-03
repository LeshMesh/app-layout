# Release process

## Current scope

The repository is public under MIT. Version 1.0.0 is the first completed release for the agreed personal-use scope. The source and arm64 archive are published on GitHub. The archive uses an ad-hoc signature and is **not Developer ID signed or notarized**. It is not advertised as a Gatekeeper-ready distribution build. Do not tell users to disable Gatekeeper or SIP.

## Publishing the current ad-hoc release

1. Run resource validation and regenerate the checked-in Xcode project.
2. Push the final source and wait for the exact commit's macOS CI to pass.
3. Inspect native screenshots (both languages/appearances and empty/paused states).
4. Download the normal build artifact from that run; do not substitute a sandbox build.
5. Name the archive `AppLayout-1.0.0-arm64.zip`, generate `SHA256SUMS.txt`, and publish both against a tag pointing to the tested commit.
6. Include source-build instructions, upgrade behavior, signing status and known test limits in the release notes.

## Before a Developer ID distribution release

1. Complete the manual checklist on supported OS versions and record results.
2. Enroll in Apple Developer Program and create a Developer ID Application certificate.
3. Keep private keys and notarization credentials out of Git. Use a dedicated local Keychain or narrowly scoped CI secrets.
4. Build the release using Developer ID, Hardened Runtime and only required entitlements.
5. Verify arm64 architecture, macOS deployment target, version metadata, resources and signature.
6. Submit the distribution archive with `xcrun notarytool`.
7. Inspect the notarization result; fix any issues rather than bypassing checks.
8. Staple and validate the ticket on the app or DMG, then validate the final downloaded/quarantined artifact on a clean Mac with default security settings.
9. Publish release notes, installation steps, checksums and known limitations.
10. Keep updates user-initiated unless an opt-in update design is explicitly agreed.

Notarization is not App Review or HIG certification. App Sandbox remains a separate technical decision. A future App Store version must meet that channel's requirements.

GitHub Actions currently has read-only repository permissions and cannot publish releases or access signing keys.
