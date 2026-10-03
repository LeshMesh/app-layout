#!/usr/bin/env python3
"""Render native settings with in-memory fixtures, without starting app automation."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys

if sys.platform != "darwin":
    raise SystemExit("Native screenshots require macOS 26 and Xcode 26 or later.")
root = Path(__file__).resolve().parent.parent
app = root / "build/preview/AppLayoutPreview.app"
macos = app / "Contents/MacOS"
resources = app / "Contents/Resources"
macos.mkdir(parents=True, exist_ok=True)
resources.mkdir(parents=True, exist_ok=True)
for language in ("en", "ru"):
    shutil.copytree(root / f"Resources/{language}.lproj",
                    resources / f"{language}.lproj", dirs_exist_ok=True)
with (app / "Contents/Info.plist").open("wb") as stream:
    plistlib.dump({
        "CFBundleIdentifier": "dev.leshmesh.AppLayout.Preview",
        "CFBundleExecutable": "AppLayoutPreview",
        "CFBundleName": "AppLayoutPreview",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "1.0.0",
        "LSUIElement": True,
        "LSMinimumSystemVersion": "26.0",
    }, stream)
sources = sorted(path for path in (root / "Sources").rglob("*.swift")
                 if path.name != "AppDelegate.swift")
subprocess.run([
    "xcrun", "swiftc", "-swift-version", "6", "-D", "APP_LAYOUT_PREVIEW",
    "-target", "arm64-apple-macosx26.0",
    *map(str, sources), str(root / "scripts/render_settings.swift"),
    "-o", str(macos / "AppLayoutPreview")
], check=True, cwd=root)
subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
subprocess.run([str(macos / "AppLayoutPreview"), str(root / "build/screenshots")],
               check=True, timeout=45)
