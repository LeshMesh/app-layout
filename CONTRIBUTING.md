# Contributing

Use Xcode 26 or later on an Apple Silicon Mac running macOS 26 or later.

Keep AppLayout focused on per-application input-source selection. Avoid keyboard hooks, Accessibility permissions, text inspection, network dependencies and persistent application-usage logs.

Run `swift test`, `python3 scripts/validate.py`, and `bash scripts/build.sh`. If you change source/resource membership, regenerate the project with `python3 scripts/generate_project.py`. Describe relevant manual checks from docs/TESTING.md in the pull request.

Use exact bundle/input-source IDs. Do not infer a source from a language label or application category. Preserve manual choices and cancel stale activation work. Add English and Russian UI strings together.

Do not commit Apple signing certificates, private keys, provisioning profiles, notarization credentials, or personal settings. Contributions are accepted under the repository's MIT license.
