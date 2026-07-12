#!/usr/bin/env python3
"""
Generates MultiConvert.xcodeproj/project.pbxproj and supporting files.
Run from the repo root: python3 gen_xcodeproj.py
"""

import os, uuid, json, textwrap

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_counter = [0]

def gen_id():
    _counter[0] += 1
    return f"{_counter[0]:024X}"

def pbx_str(s):
    if any(c in s for c in ' .-/()'):
        return f'"{s}"'
    return s

# ---------------------------------------------------------------------------
# File definitions
# ---------------------------------------------------------------------------

# (relative_path_in_project, group_path, targets)
# targets: list of target keys

APP_SOURCES = [
    "MultiConvert/App/MultiConvertApp.swift",
    "MultiConvert/App/AppState.swift",
    "MultiConvert/Models/Currency.swift",
    "MultiConvert/Models/CurrencyRate.swift",
    "MultiConvert/Services/RateProvider.swift",
    "MultiConvert/Services/FiatProvider.swift",
    "MultiConvert/Services/CryptoProvider.swift",
    "MultiConvert/Services/RateCache.swift",
    "MultiConvert/Services/ConversionEngine.swift",
    "MultiConvert/Services/PurchaseManager.swift",
    "MultiConvert/Utilities/Theme.swift",
    "MultiConvert/Utilities/CurrencyFormatter.swift",
    "MultiConvert/Utilities/MRUCache.swift",
    "MultiConvert/Views/ContentView.swift",
    "MultiConvert/Views/ConversionListView.swift",
    "MultiConvert/Views/ConversionRowView.swift",
    "MultiConvert/Views/NumericKeypad.swift",
    "MultiConvert/Views/CurrencyPickerView.swift",
    "MultiConvert/Views/CurrencyPickerSheet.swift",
    "MultiConvert/Views/SettingsView.swift",
    "MultiConvert/Views/AdBannerView.swift",
]

TEST_SOURCES = [
    "MultiConvertTests/ConversionMathTests.swift",
    "MultiConvertTests/MRUCacheTests.swift",
    "MultiConvertTests/CacheStalenessTests.swift",
    "MultiConvertTests/CurrencyFormattingTests.swift",
    "MultiConvertTests/BaseCyclerTests.swift",
    "MultiConvertTests/PurchaseManagerTests.swift",
    "MultiConvertTests/ReorderTests.swift",
    "MultiConvertTests/ReplaceCurrencyTests.swift",
    "MultiConvertTests/SwapToBaseTests.swift",
]

UITEST_SOURCES = [
    "MultiConvertUITests/MultiConvertUITests.swift",
]

WIDGET_SOURCES = [
    "MultiConvertWidget/MultiConvertWidgetBundle.swift",
    "MultiConvertWidget/MultiConvertWidget.swift",
]

APP_RESOURCES = [
    "MultiConvert/Resources/Assets.xcassets",
    "MultiConvert/Resources/MultiConvert.storekit",
]

WIDGET_RESOURCES = [
    "MultiConvertWidget/Assets.xcassets",
]

# ---------------------------------------------------------------------------
# ID registry
# ---------------------------------------------------------------------------

# We'll store: path -> { fileRef, buildFile_<target>, ... }
ids = {}

def fref(path):
    if path not in ids:
        ids[path] = {}
    if 'fileRef' not in ids[path]:
        ids[path]['fileRef'] = gen_id()
    return ids[path]['fileRef']

def bfile(path, target):
    if path not in ids:
        ids[path] = {}
    key = f'buildFile_{target}'
    if key not in ids[path]:
        ids[path][key] = gen_id()
    return ids[path][key]

# Target IDs
T_APP    = gen_id()
T_TEST   = gen_id()
T_UITEST = gen_id()
T_WIDGET = gen_id()

# Build phase IDs
BP_APP_SRC    = gen_id(); BP_APP_RES    = gen_id(); BP_APP_FW     = gen_id()
BP_TEST_SRC   = gen_id(); BP_TEST_FW    = gen_id()
BP_UITEST_SRC = gen_id(); BP_UITEST_FW  = gen_id()
BP_WIDGET_SRC = gen_id(); BP_WIDGET_RES = gen_id(); BP_WIDGET_FW  = gen_id()

# Config list IDs
CL_PROJECT = gen_id(); CL_APP = gen_id(); CL_TEST = gen_id()
CL_UITEST  = gen_id(); CL_WIDGET = gen_id()

# Config IDs (Debug/Release per target)
CFG_PROJ_DEBUG   = gen_id(); CFG_PROJ_RELEASE   = gen_id()
CFG_APP_DEBUG    = gen_id(); CFG_APP_RELEASE    = gen_id()
CFG_TEST_DEBUG   = gen_id(); CFG_TEST_RELEASE   = gen_id()
CFG_UITEST_DEBUG = gen_id(); CFG_UITEST_RELEASE = gen_id()
CFG_WIDGET_DEBUG = gen_id(); CFG_WIDGET_RELEASE = gen_id()

# Group IDs
GRP_ROOT      = gen_id()
GRP_APP_TOP   = gen_id()
GRP_APP_SUB   = gen_id()
GRP_MODELS    = gen_id()
GRP_SERVICES  = gen_id()
GRP_UTILITIES = gen_id()
GRP_VIEWS     = gen_id()
GRP_RESOURCES = gen_id()
GRP_TESTS     = gen_id()
GRP_UITESTS   = gen_id()
GRP_WIDGET    = gen_id()
GRP_PRODUCTS  = gen_id()

# Target dependency IDs
DEP_WIDGET_PROXY = gen_id()
DEP_WIDGET       = gen_id()
DEP_APP_FOR_TEST_PROXY  = gen_id()
DEP_APP_FOR_TEST        = gen_id()
DEP_APP_FOR_UITEST_PROXY = gen_id()
DEP_APP_FOR_UITEST       = gen_id()

PROJECT_ID = gen_id()

# Pre-generate all file refs
for p in APP_SOURCES + TEST_SOURCES + UITEST_SOURCES + WIDGET_SOURCES + APP_RESOURCES + WIDGET_RESOURCES:
    fref(p)

# Pre-generate all build files
for p in APP_SOURCES:
    bfile(p, 'app')
for p in APP_RESOURCES:
    bfile(p, 'app')
for p in TEST_SOURCES:
    bfile(p, 'test')
for p in UITEST_SOURCES:
    bfile(p, 'uitest')
for p in WIDGET_SOURCES:
    bfile(p, 'widget')
for p in WIDGET_RESOURCES:
    bfile(p, 'widget')

# Product file refs
PROD_APP    = gen_id()
PROD_TEST   = gen_id()
PROD_UITEST = gen_id()
PROD_WIDGET = gen_id()

# Framework refs (SwiftUI, WidgetKit etc are part of SDK, no explicit ref needed in modern Xcode)

# ---------------------------------------------------------------------------
# Build the pbxproj string
# ---------------------------------------------------------------------------

def emit_build_files():
    lines = ["/* Begin PBXBuildFile section */"]
    def add(path, target, comment=""):
        bid = bfile(path, target)
        fname = os.path.basename(path)
        lines.append(f"\t\t{bid} /* {fname} in {comment} */ = {{isa = PBXBuildFile; fileRef = {fref(path)} /* {fname} */; }};")

    for p in APP_SOURCES:
        add(p, 'app', 'Sources')
    for p in APP_RESOURCES:
        add(p, 'app', 'Resources')
    for p in TEST_SOURCES:
        add(p, 'test', 'Sources')
    for p in UITEST_SOURCES:
        add(p, 'uitest', 'Sources')
    for p in WIDGET_SOURCES:
        add(p, 'widget', 'Sources')
    for p in WIDGET_RESOURCES:
        add(p, 'widget', 'Resources')

    lines.append("/* End PBXBuildFile section */")
    return "\n".join(lines)

def file_type(path):
    if path.endswith('.swift'):     return 'sourcecode.swift'
    if path.endswith('.xcassets'):  return 'folder.assetcatalog'
    if path.endswith('.plist'):     return 'text.plist.xml'
    if path.endswith('.storekit'):  return 'com.apple.storekit.configuration'
    return 'file'

def emit_file_references():
    lines = ["/* Begin PBXFileReference section */"]
    all_files = APP_SOURCES + TEST_SOURCES + UITEST_SOURCES + WIDGET_SOURCES + APP_RESOURCES + WIDGET_RESOURCES
    for p in all_files:
        fname = os.path.basename(p)
        ftype = file_type(p)
        rid = fref(p)
        lines.append(f'\t\t{rid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {pbx_str(fname)}; sourceTree = "<group>"; }};')
    # Products
    lines.append(f'\t\t{PROD_APP} /* MultiConvert.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MultiConvert.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{PROD_TEST} /* MultiConvertTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MultiConvertTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{PROD_UITEST} /* MultiConvertUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MultiConvertUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{PROD_WIDGET} /* MultiConvertWidget.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = MultiConvertWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append("/* End PBXFileReference section */")
    return "\n".join(lines)

def children_ids(paths):
    return " ".join(f"{fref(p)} /* {os.path.basename(p)} */," for p in paths)

def emit_groups():
    lines = ["/* Begin PBXGroup section */"]

    # Root group
    lines.append(f"""\t\t{GRP_ROOT} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{GRP_APP_TOP} /* MultiConvert */,
\t\t\t\t{GRP_TESTS} /* MultiConvertTests */,
\t\t\t\t{GRP_UITESTS} /* MultiConvertUITests */,
\t\t\t\t{GRP_WIDGET} /* MultiConvertWidget */,
\t\t\t\t{GRP_PRODUCTS} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Products
    lines.append(f"""\t\t{GRP_PRODUCTS} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{PROD_APP} /* MultiConvert.app */,
\t\t\t\t{PROD_TEST} /* MultiConvertTests.xctest */,
\t\t\t\t{PROD_UITEST} /* MultiConvertUITests.xctest */,
\t\t\t\t{PROD_WIDGET} /* MultiConvertWidget.appex */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # MultiConvert top group
    lines.append(f"""\t\t{GRP_APP_TOP} /* MultiConvert */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{GRP_APP_SUB} /* App */,
\t\t\t\t{GRP_MODELS} /* Models */,
\t\t\t\t{GRP_SERVICES} /* Services */,
\t\t\t\t{GRP_UTILITIES} /* Utilities */,
\t\t\t\t{GRP_VIEWS} /* Views */,
\t\t\t\t{GRP_RESOURCES} /* Resources */,
\t\t\t);
\t\t\tpath = MultiConvert;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    def sub_group(gid, name, dir_path, paths):
        files = [p for p in paths if p.startswith(dir_path + '/') or p.startswith('MultiConvert/' + name + '/')]
        children = "\n".join(f"\t\t\t\t{fref(p)} /* {os.path.basename(p)} */," for p in files)
        return f"""\t\t{gid} /* {name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}
\t\t\t);
\t\t\tpath = {name};
\t\t\tsourceTree = "<group>";
\t\t}};"""

    app_files  = [p for p in APP_SOURCES if '/App/' in p]
    model_files = [p for p in APP_SOURCES if '/Models/' in p]
    svc_files  = [p for p in APP_SOURCES if '/Services/' in p]
    util_files = [p for p in APP_SOURCES if '/Utilities/' in p]
    view_files = [p for p in APP_SOURCES if '/Views/' in p]
    res_files  = APP_RESOURCES

    def simple_group(gid, name, files):
        children = "\n".join(f"\t\t\t\t{fref(p)} /* {os.path.basename(p)} */," for p in files)
        return f"""\t\t{gid} /* {name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}
\t\t\t);
\t\t\tpath = {name};
\t\t\tsourceTree = "<group>";
\t\t}};"""

    lines.append(simple_group(GRP_APP_SUB,   'App',       app_files))
    lines.append(simple_group(GRP_MODELS,    'Models',    model_files))
    lines.append(simple_group(GRP_SERVICES,  'Services',  svc_files))
    lines.append(simple_group(GRP_UTILITIES, 'Utilities', util_files))
    lines.append(simple_group(GRP_VIEWS,     'Views',     view_files))
    lines.append(simple_group(GRP_RESOURCES, 'Resources', res_files))

    # Tests
    test_children = "\n".join(f"\t\t\t\t{fref(p)} /* {os.path.basename(p)} */," for p in TEST_SOURCES)
    lines.append(f"""\t\t{GRP_TESTS} /* MultiConvertTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{test_children}
\t\t\t);
\t\t\tpath = MultiConvertTests;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # UITests
    uitest_children = "\n".join(f"\t\t\t\t{fref(p)} /* {os.path.basename(p)} */," for p in UITEST_SOURCES)
    lines.append(f"""\t\t{GRP_UITESTS} /* MultiConvertUITests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{uitest_children}
\t\t\t);
\t\t\tpath = MultiConvertUITests;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    # Widget
    widget_all = WIDGET_SOURCES + WIDGET_RESOURCES
    widget_children = "\n".join(f"\t\t\t\t{fref(p)} /* {os.path.basename(p)} */," for p in widget_all)
    lines.append(f"""\t\t{GRP_WIDGET} /* MultiConvertWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{widget_children}
\t\t\t);
\t\t\tpath = MultiConvertWidget;
\t\t\tsourceTree = "<group>";
\t\t}};""")

    lines.append("/* End PBXGroup section */")
    return "\n".join(lines)

def sources_phase(phase_id, comment, paths, target_key):
    files = "\n".join(f"\t\t\t\t{bfile(p, target_key)} /* {os.path.basename(p)} in Sources */," for p in paths)
    return f"""\t\t{phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

def resources_phase(phase_id, comment, paths, target_key):
    files = "\n".join(f"\t\t\t\t{bfile(p, target_key)} /* {os.path.basename(p)} in Resources */," for p in paths)
    return f"""\t\t{phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

def frameworks_phase(phase_id):
    return f"""\t\t{phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

def emit_build_phases():
    lines = ["/* Begin PBXSourcesBuildPhase section */"]
    lines.append(sources_phase(BP_APP_SRC,    'Sources', APP_SOURCES,    'app'))
    lines.append(sources_phase(BP_TEST_SRC,   'Sources', TEST_SOURCES,   'test'))
    lines.append(sources_phase(BP_UITEST_SRC, 'Sources', UITEST_SOURCES, 'uitest'))
    lines.append(sources_phase(BP_WIDGET_SRC, 'Sources', WIDGET_SOURCES, 'widget'))
    lines.append("/* End PBXSourcesBuildPhase section */")

    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(resources_phase(BP_APP_RES,    'Resources', APP_RESOURCES,    'app'))
    lines.append(resources_phase(BP_WIDGET_RES, 'Resources', WIDGET_RESOURCES, 'widget'))
    lines.append("/* End PBXResourcesBuildPhase section */")

    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    for pid in [BP_APP_FW, BP_TEST_FW, BP_UITEST_FW, BP_WIDGET_FW]:
        lines.append(frameworks_phase(pid))
    lines.append("/* End PBXFrameworksBuildPhase section */")

    return "\n".join(lines)

def emit_container_proxy_and_dep():
    lines = ["/* Begin PBXContainerItemProxy section */"]

    def proxy(pid, tid, name):
        return f"""\t\t{pid} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {PROJECT_ID} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {tid};
\t\t\tremoteInfo = {name};
\t\t}};"""

    lines.append(proxy(DEP_WIDGET_PROXY, T_WIDGET, 'MultiConvertWidget'))
    lines.append(proxy(DEP_APP_FOR_TEST_PROXY, T_APP, 'MultiConvert'))
    lines.append(proxy(DEP_APP_FOR_UITEST_PROXY, T_APP, 'MultiConvert'))
    lines.append("/* End PBXContainerItemProxy section */")

    lines.append("/* Begin PBXTargetDependency section */")

    def dep(did, tid, name, pid):
        return f"""\t\t{did} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {tid} /* {name} */;
\t\t\ttargetProxy = {pid} /* PBXContainerItemProxy */;
\t\t}};"""

    lines.append(dep(DEP_WIDGET, T_WIDGET, 'MultiConvertWidget', DEP_WIDGET_PROXY))
    lines.append(dep(DEP_APP_FOR_TEST, T_APP, 'MultiConvert', DEP_APP_FOR_TEST_PROXY))
    lines.append(dep(DEP_APP_FOR_UITEST, T_APP, 'MultiConvert', DEP_APP_FOR_UITEST_PROXY))
    lines.append("/* End PBXTargetDependency section */")
    return "\n".join(lines)

def emit_native_targets():
    lines = ["/* Begin PBXNativeTarget section */"]

    lines.append(f"""\t\t{T_APP} /* MultiConvert */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CL_APP} /* Build configuration list for PBXNativeTarget "MultiConvert" */;
\t\t\tbuildPhases = (
\t\t\t\t{BP_APP_SRC} /* Sources */,
\t\t\t\t{BP_APP_FW} /* Frameworks */,
\t\t\t\t{BP_APP_RES} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{DEP_WIDGET} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = MultiConvert;
\t\t\tproductName = MultiConvert;
\t\t\tproductReference = {PROD_APP} /* MultiConvert.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};""")

    lines.append(f"""\t\t{T_TEST} /* MultiConvertTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CL_TEST} /* Build configuration list for PBXNativeTarget "MultiConvertTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{BP_TEST_SRC} /* Sources */,
\t\t\t\t{BP_TEST_FW} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{DEP_APP_FOR_TEST} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = MultiConvertTests;
\t\t\tproductName = MultiConvertTests;
\t\t\tproductReference = {PROD_TEST} /* MultiConvertTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};""")

    lines.append(f"""\t\t{T_UITEST} /* MultiConvertUITests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CL_UITEST} /* Build configuration list for PBXNativeTarget "MultiConvertUITests" */;
\t\t\tbuildPhases = (
\t\t\t\t{BP_UITEST_SRC} /* Sources */,
\t\t\t\t{BP_UITEST_FW} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{DEP_APP_FOR_UITEST} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = MultiConvertUITests;
\t\t\tproductName = MultiConvertUITests;
\t\t\tproductReference = {PROD_UITEST} /* MultiConvertUITests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};""")

    lines.append(f"""\t\t{T_WIDGET} /* MultiConvertWidget */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CL_WIDGET} /* Build configuration list for PBXNativeTarget "MultiConvertWidget" */;
\t\t\tbuildPhases = (
\t\t\t\t{BP_WIDGET_SRC} /* Sources */,
\t\t\t\t{BP_WIDGET_FW} /* Frameworks */,
\t\t\t\t{BP_WIDGET_RES} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = MultiConvertWidget;
\t\t\tproductName = MultiConvertWidget;
\t\t\tproductReference = {PROD_WIDGET} /* MultiConvertWidget.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};""")

    lines.append("/* End PBXNativeTarget section */")
    return "\n".join(lines)

def build_settings(cfg, target):
    common = {
        'ALWAYS_SEARCH_USER_PATHS': 'NO',
        'CLANG_ANALYZER_NONNULL': 'YES',
        'CLANG_CXX_LANGUAGE_STANDARD': '"gnu++20"',
        'COPY_PHASE_STRIP': 'NO' if cfg == 'Debug' else 'YES',
        'DEBUG_INFORMATION_FORMAT': 'dwarf' if cfg == 'Debug' else '"dwarf-with-dsym"',
        'ENABLE_STRICT_OBJC_MSGSEND': 'YES',
        'GCC_C_LANGUAGE_STANDARD': 'gnu17',
        'GCC_DYNAMIC_NO_PIC': 'NO',
        'GCC_NO_COMMON_BLOCKS': 'YES',
        'GCC_OPTIMIZATION_LEVEL': '0' if cfg == 'Debug' else 's',
        'GCC_WARN_64_TO_32_BIT_CONVERSION': 'YES',
        'GCC_WARN_ABOUT_RETURN_TYPE': 'YES_ERROR',
        'GCC_WARN_UNDECLARED_SELECTOR': 'YES',
        'GCC_WARN_UNINITIALIZED_AUTOS': 'YES_AGGRESSIVE',
        'GCC_WARN_UNUSED_FUNCTION': 'YES',
        'GCC_WARN_UNUSED_VARIABLE': 'YES',
        'IPHONEOS_DEPLOYMENT_TARGET': '17.0',
        'MTL_ENABLE_DEBUG_INFO': '"INCLUDE_SOURCE"' if cfg == 'Debug' else 'NO',
        'MTL_FAST_MATH': 'YES',
        'SDKROOT': 'iphoneos',
        'SWIFT_OPTIMIZATION_LEVEL': '"-Onone"' if cfg == 'Debug' else '"-O"',
        'SWIFT_VERSION': '5.0',
    }
    if cfg == 'Debug':
        common['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    if cfg == 'Release':
        common['VALIDATE_PRODUCT'] = 'YES'

    common['DEVELOPMENT_TEAM'] = 'RK576HX8MX'

    if target == 'project':
        return common

    extras = {}
    if target == 'app':
        extras = {
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
            'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME': 'AccentColor',
            'CODE_SIGN_STYLE': 'Automatic',
            'CURRENT_PROJECT_VERSION': '1',
            'ENABLE_PREVIEWS': 'YES',
            'ENABLE_TESTABILITY': 'YES',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'INFOPLIST_KEY_CFBundleDisplayName': 'MultiConvert',
            'INFOPLIST_KEY_NSHumanReadableCopyright': '"© 2025 jibaroenlaluna"',
            'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
            'INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents': 'YES',
            'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
            'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone': '"UIInterfaceOrientationPortrait"',
            'MARKETING_VERSION': '1.0',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.jibaroenlaluna.multiconvert',
            'PRODUCT_NAME': '"$(TARGET_NAME)"',
            'SWIFT_EMIT_LOC_STRINGS': 'YES',
            'TARGETED_DEVICE_FAMILY': '"1"',
        }
    elif target == 'test':
        extras = {
            'BUNDLE_LOADER': '"$(TEST_HOST)"',
            'CODE_SIGN_STYLE': 'Automatic',
            'CURRENT_PROJECT_VERSION': '1',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'MARKETING_VERSION': '1.0',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.jibaroenlaluna.multiconvert.tests',
            'PRODUCT_NAME': '"$(TARGET_NAME)"',
            'SWIFT_EMIT_LOC_STRINGS': 'NO',
            'TARGETED_DEVICE_FAMILY': '"1"',
            'TEST_HOST': '"$(BUILT_PRODUCTS_DIR)/MultiConvert.app/MultiConvert"',
        }
    elif target == 'uitest':
        extras = {
            'CODE_SIGN_STYLE': 'Automatic',
            'CURRENT_PROJECT_VERSION': '1',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'MARKETING_VERSION': '1.0',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.jibaroenlaluna.multiconvert.uitests',
            'PRODUCT_NAME': '"$(TARGET_NAME)"',
            'SWIFT_EMIT_LOC_STRINGS': 'NO',
            'TARGETED_DEVICE_FAMILY': '"1"',
            'TEST_TARGET_NAME': 'MultiConvert',
        }
    elif target == 'widget':
        extras = {
            'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME': 'AccentColor',
            'CODE_SIGN_STYLE': 'Automatic',
            'CURRENT_PROJECT_VERSION': '1',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'INFOPLIST_KEY_CFBundleDisplayName': 'MultiConvertWidget',
            'INFOPLIST_KEY_NSExtensionPointIdentifier': '"com.apple.widgetkit-extension"',
            'MARKETING_VERSION': '1.0',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.jibaroenlaluna.multiconvert.widget',
            'PRODUCT_NAME': '"$(TARGET_NAME)"',
            'SKIP_INSTALL': 'YES',
            'SWIFT_EMIT_LOC_STRINGS': 'YES',
            'TARGETED_DEVICE_FAMILY': '"1"',
        }
    common.update(extras)
    return common

def settings_block(d):
    lines = []
    for k, v in sorted(d.items()):
        lines.append(f"\t\t\t\t{k} = {v};")
    return "\n".join(lines)

def emit_configurations():
    lines = ["/* Begin XCBuildConfiguration section */"]

    specs = [
        (CFG_PROJ_DEBUG,   'project', 'Debug'),
        (CFG_PROJ_RELEASE, 'project', 'Release'),
        (CFG_APP_DEBUG,    'app',     'Debug'),
        (CFG_APP_RELEASE,  'app',     'Release'),
        (CFG_TEST_DEBUG,   'test',    'Debug'),
        (CFG_TEST_RELEASE, 'test',    'Release'),
        (CFG_UITEST_DEBUG, 'uitest',  'Debug'),
        (CFG_UITEST_RELEASE,'uitest', 'Release'),
        (CFG_WIDGET_DEBUG, 'widget',  'Debug'),
        (CFG_WIDGET_RELEASE,'widget', 'Release'),
    ]

    for cid, target, cfg in specs:
        s = settings_block(build_settings(cfg, target))
        lines.append(f"""\t\t{cid} /* {cfg} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{s}
\t\t\t}};
\t\t\tname = {cfg};
\t\t}};""")

    lines.append("/* End XCBuildConfiguration section */")
    return "\n".join(lines)

def emit_config_lists():
    lines = ["/* Begin XCConfigurationList section */"]

    lists = [
        (CL_PROJECT, 'PBXProject',      'MultiConvert',         CFG_PROJ_DEBUG,   CFG_PROJ_RELEASE),
        (CL_APP,     'PBXNativeTarget', 'MultiConvert',         CFG_APP_DEBUG,    CFG_APP_RELEASE),
        (CL_TEST,    'PBXNativeTarget', 'MultiConvertTests',    CFG_TEST_DEBUG,   CFG_TEST_RELEASE),
        (CL_UITEST,  'PBXNativeTarget', 'MultiConvertUITests',  CFG_UITEST_DEBUG, CFG_UITEST_RELEASE),
        (CL_WIDGET,  'PBXNativeTarget', 'MultiConvertWidget',   CFG_WIDGET_DEBUG, CFG_WIDGET_RELEASE),
    ]

    for clid, kind, name, dbg, rel in lists:
        lines.append(f"""\t\t{clid} /* Build configuration list for {kind} "{name}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{dbg} /* Debug */,
\t\t\t\t{rel} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")

    lines.append("/* End XCConfigurationList section */")
    return "\n".join(lines)

def emit_project():
    return f"""/* Begin PBXProject section */
\t\t{PROJECT_ID} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{T_APP} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{T_TEST} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {T_APP};
\t\t\t\t\t}};
\t\t\t\t\t{T_UITEST} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {T_APP};
\t\t\t\t\t}};
\t\t\t\t\t{T_WIDGET} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {CL_PROJECT} /* Build configuration list for PBXProject "MultiConvert" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {GRP_ROOT};
\t\t\tminimumXcodeVersion = 15.0;
\t\t\tproductRefGroup = {GRP_PRODUCTS} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{T_APP} /* MultiConvert */,
\t\t\t\t{T_TEST} /* MultiConvertTests */,
\t\t\t\t{T_UITEST} /* MultiConvertUITests */,
\t\t\t\t{T_WIDGET} /* MultiConvertWidget */,
\t\t\t);
\t\t}};
/* End PBXProject section */"""

# ---------------------------------------------------------------------------
# Assemble
# ---------------------------------------------------------------------------

def generate_pbxproj():
    sections = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
        emit_build_files(),
        "",
        emit_container_proxy_and_dep(),
        "",
        emit_file_references(),
        "",
        emit_groups(),
        "",
        emit_build_phases(),
        "",
        emit_native_targets(),
        "",
        emit_project(),
        "",
        emit_configurations(),
        "",
        emit_config_lists(),
        "",
        "\t};",
        f"\trootObject = {PROJECT_ID} /* Project object */;",
        "}",
    ]
    return "\n".join(sections)

# ---------------------------------------------------------------------------
# xcscheme
# ---------------------------------------------------------------------------

SCHEME = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{T_APP}"
               BuildableName = "MultiConvert.app"
               BlueprintName = "MultiConvert"
               ReferencedContainer = "container:MultiConvert.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{T_TEST}"
               BuildableName = "MultiConvertTests.xctest"
               BlueprintName = "MultiConvertTests"
               ReferencedContainer = "container:MultiConvert.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{T_UITEST}"
               BuildableName = "MultiConvertUITests.xctest"
               BlueprintName = "MultiConvertUITests"
               ReferencedContainer = "container:MultiConvert.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{T_APP}"
            BuildableName = "MultiConvert.app"
            BlueprintName = "MultiConvert"
            ReferencedContainer = "container:MultiConvert.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{T_APP}"
            BuildableName = "MultiConvert.app"
            BlueprintName = "MultiConvert"
            ReferencedContainer = "container:MultiConvert.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

WORKSPACE_DATA = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

# ---------------------------------------------------------------------------
# Write files
# ---------------------------------------------------------------------------

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  wrote {path}")

if __name__ == '__main__':
    base = os.path.dirname(os.path.abspath(__file__))
    proj = os.path.join(base, 'MultiConvert.xcodeproj')

    write(os.path.join(proj, 'project.pbxproj'), generate_pbxproj())
    write(os.path.join(proj, 'xcshareddata', 'xcschemes', 'MultiConvert.xcscheme'), SCHEME)
    write(os.path.join(proj, 'project.xcworkspace', 'contents.xcworkspacedata'), WORKSPACE_DATA)
    print("Done. Open MultiConvert.xcodeproj in Xcode 15+.")
