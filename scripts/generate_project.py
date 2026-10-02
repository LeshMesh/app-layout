#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project. Python standard library only."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def uid(label):
    return hashlib.sha256(label.encode()).hexdigest()[:24].upper()

def quoted(value):
    return json.dumps(str(value), ensure_ascii=False)

objects = []
def add(label, value):
    objects.append(f"\t\t{uid(label)} = {{ {value} }};")
    return uid(label)

sources = sorted((ROOT / "Sources").rglob("*.swift"), key=lambda path: path.relative_to(ROOT).as_posix())
source_refs = []
source_builds = []
for path in sources:
    relative = path.relative_to(ROOT).as_posix()
    ref = add(relative, f"isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(relative)}; sourceTree = SOURCE_ROOT;")
    source_refs.append(ref)
    source_builds.append(add("build:" + relative, f"isa = PBXBuildFile; fileRef = {ref};"))

resource_refs = []
resource_builds = []
for relative, file_type in [
    ("Resources/PrivacyInfo.xcprivacy", "text.xml"),
    ("Resources/Assets.xcassets", "folder.assetcatalog"),
    ("Resources/Help.html", "text.html"),
]:
    ref = add(relative, f"isa = PBXFileReference; lastKnownFileType = {file_type}; path = {quoted(relative)}; sourceTree = SOURCE_ROOT;")
    resource_refs.append(ref)
    resource_builds.append(add("build:" + relative, f"isa = PBXBuildFile; fileRef = {ref};"))

localizations = []
for language in ("en", "ru"):
    relative = f"Resources/{language}.lproj/Localizable.strings"
    localizations.append(add(relative, f"isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {language}; path = {quoted(relative)}; sourceTree = SOURCE_ROOT;"))
localized = add("strings", f"isa = PBXVariantGroup; children = ({','.join(localizations)},); name = Localizable.strings; sourceTree = \"<group>\";")
resource_refs.append(localized)
resource_builds.append(add("strings-build", f"isa = PBXBuildFile; fileRef = {localized};"))

info = add("info", 'isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Resources/Info.plist; sourceTree = SOURCE_ROOT;')
product = add("product", 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AppLayout.app; sourceTree = BUILT_PRODUCTS_DIR;')
source_group = add("source-group", f"isa = PBXGroup; children = ({','.join(source_refs)},); name = Sources; sourceTree = \"<group>\";")
resource_group = add("resource-group", f"isa = PBXGroup; children = ({','.join(resource_refs + [info])},); name = Resources; sourceTree = \"<group>\";")
products_group = add("products", f"isa = PBXGroup; children = ({product},); name = Products; sourceTree = \"<group>\";")
main_group = add("main-group", f"isa = PBXGroup; children = ({source_group},{resource_group},{products_group},); sourceTree = \"<group>\";")
sources_phase = add("sources-phase", f"isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({','.join(source_builds)},); runOnlyForDeploymentPostprocessing = 0;")
resources_phase = add("resources-phase", f"isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({','.join(resource_builds)},); runOnlyForDeploymentPostprocessing = 0;")
frameworks_phase = add("frameworks-phase", "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")

def configuration_list(label, settings):
    configs = []
    for name in ("Debug", "Release"):
        current = dict(settings)
        if label == "project":
            current["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone" if name == "Debug" else "-O"
            current["DEBUG_INFORMATION_FORMAT"] = "dwarf" if name == "Debug" else "dwarf-with-dsym"
            if name == "Debug":
                current["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
                current["ENABLE_TESTABILITY"] = "YES"
        body = " ".join(f"{key} = {quoted(value)};" for key, value in sorted(current.items()))
        configs.append(add(f"{label}-{name}", f"isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {name};"))
    return add(label + "-configs", f"isa = XCConfigurationList; buildConfigurations = ({','.join(configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;")

project_configs = configuration_list("project", {
    "ALWAYS_SEARCH_USER_PATHS": "NO", "CLANG_ENABLE_MODULES": "YES",
    "MACOSX_DEPLOYMENT_TARGET": "26.0", "SDKROOT": "macosx",
    "SWIFT_VERSION": "6.0", "SWIFT_STRICT_CONCURRENCY": "complete",
    "GCC_WARN_UNDECLARED_SELECTOR": "YES",
})
target_configs = configuration_list("target", {
    "ARCHS": "arm64", "ONLY_ACTIVE_ARCH": "YES",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_IDENTITY": "-", "CODE_SIGN_STYLE": "Manual",
    "COMBINE_HIDPI_IMAGES": "YES", "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_APP_SANDBOX": "NO", "ENABLE_HARDENED_RUNTIME": "YES",
    "GENERATE_INFOPLIST_FILE": "NO", "INFOPLIST_FILE": "Resources/Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/../Frameworks",
    "MARKETING_VERSION": "0.1.0", "PRODUCT_BUNDLE_IDENTIFIER": "dev.leshmesh.AppLayout",
    "PRODUCT_NAME": "$(TARGET_NAME)", "SWIFT_EMIT_LOC_STRINGS": "NO",
})
target = add("target", f"isa = PBXNativeTarget; buildConfigurationList = {target_configs}; buildPhases = ({sources_phase},{frameworks_phase},{resources_phase},); buildRules = (); dependencies = (); name = AppLayout; productName = AppLayout; productReference = {product}; productType = \"com.apple.product-type.application\";")
project = add("project", f"isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2600; }}; buildConfigurationList = {project_configs}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,ru,Base,); mainGroup = {main_group}; productRefGroup = {products_group}; projectDirPath = \"\"; projectRoot = \"\"; targets = ({target},);")

directory = ROOT / "AppLayout.xcodeproj"
directory.mkdir(exist_ok=True)
content = "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n"
content += "\n".join(objects) + f"\n\t}};\n\trootObject = {project};\n}}\n"
(directory / "project.pbxproj").write_text(content, encoding="utf-8", newline="\n")
scheme_dir = directory / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="AppLayout.app" BlueprintName="AppLayout" ReferencedContainer="container:AppLayout.xcodeproj"/>'
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
(scheme_dir / "AppLayout.xcscheme").write_text(scheme, encoding="utf-8", newline="\n")
print(f"Generated Xcode project: {len(sources)} Swift source files")
