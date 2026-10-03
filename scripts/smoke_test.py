#!/usr/bin/env python3
"""Launch the native app on a disposable GitHub macOS runner; no keyboard simulation."""
import json
import os
from pathlib import Path
import subprocess
import sys

if sys.platform != "darwin" or os.environ.get("GITHUB_ACTIONS") != "true":
    raise SystemExit("This smoke check is for a disposable GitHub macOS runner only.")

root = Path(__file__).resolve().parent.parent
app = root / "build/local/Build/Products/Release/AppLayout.app"
executable = app / "Contents/MacOS/AppLayout"
settings = Path.home() / "Library/Application Support/AppLayout/settings.json"
if settings.exists():
    raise SystemExit("Expected a clean runner without existing AppLayout settings.")
for resource in ("en.lproj/Localizable.strings", "ru.lproj/Localizable.strings",
                 "Help.html", "PrivacyInfo.xcprivacy", "AppIcon.icns"):
    assert (app / "Contents/Resources" / resource).exists(), resource

process = subprocess.Popen([str(executable)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
try:
    try:
        stdout, stderr = process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        assert settings.exists(), "First launch did not create settings"
        preferences = json.loads(settings.read_text())
        assert preferences["hasCompletedWelcome"] is True
        assert preferences["hasInitializedLoginItem"] is True
        assert preferences["rules"] == []
        assert preferences["isPaused"] is False
        print("Native app remained alive; first-launch settings and bundled resources verified.")
    else:
        raise RuntimeError(f"App exited unexpectedly ({process.returncode}):\n{stdout}\n{stderr}")
finally:
    if process.poll() is None:
        process.terminate()
    try:
        process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.communicate()
