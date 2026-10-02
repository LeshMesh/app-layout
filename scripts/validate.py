#!/usr/bin/env python3
"""Portable checks for plist resources, localization coverage and project inputs."""
import json
import plistlib
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
for name in ("Info.plist", "PrivacyInfo.xcprivacy", "Sandbox.entitlements"):
    with (root / "Resources" / name).open("rb") as stream:
        plistlib.load(stream)
translations = {}
for language in ("en", "ru"):
    source = (root / f"Resources/{language}.lproj/Localizable.strings").read_text(encoding="utf-8")
    entries = re.findall(r'^("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*");$', source, flags=re.M)
    translations[language] = {json.loads(key): json.loads(value) for key, value in entries}
    assert len(entries) == len(source.splitlines()), f"Malformed strings: {language}"
assert translations["en"].keys() == translations["ru"].keys(), "Localization keys differ"
used = set()
for path in (root / "Sources").rglob("*.swift"):
    used.update(re.findall(r'(?:text\(|key:\s*|issueKey\s*=\s*)"([\w.]+)"', path.read_text(encoding="utf-8")))
assert used <= translations["en"].keys(), f"Missing translations: {used - translations['en'].keys()}"
for catalog in (root / "Resources/Assets.xcassets").rglob("Contents.json"):
    value = json.loads(catalog.read_text(encoding="utf-8"))
    for image in value.get("images", []):
        assert (catalog.parent / image["filename"]).is_file()
print(f"Validated plists, assets, and {len(translations['en'])} English/Russian strings")
