# Release process

## Current scope

The repository is public under MIT. Version 0.1.0 is for building locally. CI artifacts use an ad-hoc signature and are **not notarized**. They are not advertised as normal Gatekeeper-ready distribution builds. Do not tell users to disable Gatekeeper or SIP.

## Before a public binary release

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
