---
name: cmake-review
description: Reviews CMakeLists.txt files for modern target_-prefixed commands, source globbing risks, policy correctness, dependency strategy, install rules, and CTest integration with ranked findings and file:line references.
version: 1.0.0
when_to_use: User invokes "/cmake-review", asks to "review the CMake build", or wants a sanity check on a new CMakeLists.txt before merging.
inputs:
  - name: target
    description: Optional CMakeLists.txt path or directory. Defaults to all CMakeLists.txt files changed on the current branch.
required_tools: [bash, read]
---

# CMake Review Skill

## Goal

Read the project's CMakeLists.txt files and report ranked findings against a checklist of modern CMake practice. Output is a list of findings, not edits; this skill never rewrites build files.

## Inputs

- `target`: a CMakeLists.txt path, a directory containing one, or empty to scan changed files on the branch.

## Steps

1. Detect the minimum CMake version the project declares.
   ```bash
   grep -nE 'cmake_minimum_required\s*\(\s*VERSION' "$cmakelists"
   ```
   - <3.5: legacy; recommend bumping but warn that bumping changes default policies.
   - 3.5–3.13: pre-target-centric era; many findings expected.
   - 3.14+: modern target-centric CMake is fully available.
   - 3.21+: presets, `--install --prefix` overrides, `IMPORTED_RUNTIME_ARTIFACTS`.

2. Resolve target files.
   ```bash
   git diff --name-only --diff-filter=ACMRT \
     $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main) \
     -- 'CMakeLists.txt' '**/CMakeLists.txt' '*.cmake'
   ```

3. Apply this checklist to each file. Each finding gets a severity (HIGH / MEDIUM / LOW), a file:line, and a one-line rationale.

   ### A. Target-centric commands (HIGH if violated)

   | Legacy | Modern |
   |--------|--------|
   | `include_directories(...)` | `target_include_directories(<tgt> PUBLIC|PRIVATE|INTERFACE ...)` |
   | `add_definitions(-DFOO)` | `target_compile_definitions(<tgt> ...)` |
   | `add_compile_options(...)` | `target_compile_options(<tgt> ...)` |
   | `link_libraries(...)` | `target_link_libraries(<tgt> ...)` |
   | `link_directories(...)` | `target_link_directories(<tgt> ...)` (last resort; prefer imported targets) |
   | `set(CMAKE_CXX_FLAGS "...")` | `target_compile_options(<tgt> PRIVATE ...)` |

   ### B. Source globbing (HIGH)

   ```bash
   grep -nE 'file\s*\(\s*GLOB' "$cmakelists"
   ```
   `file(GLOB SOURCES ...)` and `file(GLOB_RECURSE ...)` cause stale builds when files are added/removed. CMake will not re-run unless something else changes. The fix is to list sources explicitly. `CONFIGURE_DEPENDS` mitigates but does not eliminate the issue and adds per-build cost.

   ### C. Policies and standards (MEDIUM)

   - `cmake_policy(SET CMP0048 NEW)` and similar should be set explicitly when crossing a behavior change.
   - `set(CMAKE_CXX_STANDARD 17)` is fine but should be paired with `set(CMAKE_CXX_STANDARD_REQUIRED ON)` and `set(CMAKE_CXX_EXTENSIONS OFF)` to make portable builds reproducible.
   - Setting standards on individual targets (`target_compile_features(<tgt> PUBLIC cxx_std_17)`) is preferred over global flags.

   ### D. Dependency acquisition (MEDIUM)

   | Pattern | When |
   |---------|------|
   | `find_package(Foo CONFIG REQUIRED)` | Library is installed system-wide / via package manager / via vcpkg / via conan. Preferred for everything that ships a `FooConfig.cmake`. |
   | `find_package(Foo MODULE REQUIRED)` | CMake bundles the `FindFoo.cmake`. |
   | `FetchContent_Declare(...)` + `FetchContent_MakeAvailable(...)` | Source-level dependency, transitively builds. Reproducible only if a tag or commit hash is pinned (HIGH if `master` or `main` is used). |
   | `ExternalProject_Add(...)` | Build-time external project (separate build tree). Heavier than FetchContent; usually only needed when target consumption is not via CMake. |
   | `add_subdirectory(third_party/foo)` | Vendored source. Note: pollutes the parent target/option namespace. |

   Flag mixing of strategies inconsistently across the same dependency (e.g., `find_package` in one file and `FetchContent_Declare` in another).

   ### E. Install rules (MEDIUM)

   - `install(TARGETS <tgt> EXPORT <tgt>Targets ...)` should be paired with `install(EXPORT <tgt>Targets ...)` and a generated `<pkg>Config.cmake` so downstream `find_package(<pkg> CONFIG)` works.
   - Use `GNUInstallDirs` (`include(GNUInstallDirs)`) instead of hardcoding `lib/`, `bin/`, etc.
   - Public headers should use `FILE_SET HEADERS` (CMake 3.23+) or be installed with `install(FILES ...)` plus matching `target_include_directories(<tgt> PUBLIC $<INSTALL_INTERFACE:include>)`.

   ### F. Testing (LOW unless tests exist)

   - If `enable_testing()` is called, gate it behind `if(BUILD_TESTING)` and `include(CTest)` — `CTest` defines `BUILD_TESTING ON` by default but allows downstream consumers to opt out.
   - `add_test(NAME <n> COMMAND <tgt>)` is preferred over `add_test(<n> <tgt>)` (the legacy short form does not support generator expressions).

   ### G. Warnings as errors (LOW)

   - Project-wide `-Werror` makes consumers fail when their compiler is newer; gate behind an `option(<PROJECT>_WERROR ...)`. CI can set it; library users should not be forced.

   ### H. Generator expressions (LOW)

   - `target_compile_options(<tgt> PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Wall>)` is preferred over `if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU") ...`.

   ### I. Position-independent code (LOW)

   - For shared libraries that consume static libraries, set `set_target_properties(<static-lib> PROPERTIES POSITION_INDEPENDENT_CODE ON)` or `target_compile_options(<tgt> PRIVATE -fPIC)`. Missing PIC on a static dependency causes link failures on some platforms.

4. Cross-cutting checks:
   - `project(<name> VERSION x.y.z LANGUAGES CXX)` declared early, before `find_package` calls.
   - `option(BUILD_SHARED_LIBS ...)` honored if the project produces libraries.
   - No `set(CMAKE_BUILD_TYPE Debug)` inside `CMakeLists.txt` — that overrides the user's choice.
   - No assumption of in-source builds; reject `${CMAKE_SOURCE_DIR}` writes.
   - `CMAKE_RUNTIME_OUTPUT_DIRECTORY` and friends, if set, should be set per-target rather than globally to avoid surprising downstream consumers via `add_subdirectory`.

5. Optional extras when the project ships them:
   - `CMakePresets.json` (CMake 3.21+) — verify `version`, `cmakeMinimumRequired`, and that presets do not hardcode absolute paths.
   - `cmake/` modules — flag `include(<name>)` referring to modules not present in the tree.
   - `.cmake-format.yaml` / `.cmake-format.json` — if present, mention that style is enforced, but do not run the formatter from this skill.
   - `ccache` / `sccache` integration — `set(CMAKE_C_COMPILER_LAUNCHER ccache)` is a portability concern only if mandatory.

## Output format

```markdown
### cmake-review report

Files reviewed: 3
Minimum CMake version declared: 3.10 (recommend 3.21+ for current best practice)

#### CMakeLists.txt (12 findings)
- HIGH  L8   `include_directories(include)` → `target_include_directories(mylib PUBLIC include)` (legacy global include)
- HIGH  L24  `file(GLOB SOURCES src/*.cpp)` → list sources explicitly; CONFIGURE_DEPENDS mitigates but does not fix
- HIGH  L41  `add_definitions(-DLOG_LEVEL=2)` → `target_compile_definitions(mylib PRIVATE LOG_LEVEL=2)`
- MEDIUM L57 `FetchContent_Declare(spdlog GIT_TAG main)` → pin a tag or commit hash for reproducibility
- MEDIUM L72 `set(CMAKE_CXX_STANDARD 17)` without `CMAKE_CXX_STANDARD_REQUIRED ON` and `CMAKE_CXX_EXTENSIONS OFF`
- MEDIUM L85 `install(TARGETS mylib DESTINATION lib)` → use `GNUInstallDirs` and `EXPORT` set
- LOW   L102 `if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")` → generator expression `$<$<CXX_COMPILER_ID:GNU>:...>`
...

#### tests/CMakeLists.txt (2 findings)
- MEDIUM L4  `enable_testing()` not gated on BUILD_TESTING
- LOW   L18 `add_test(parser_test parser_test)` → use `NAME ... COMMAND ...` form
```

## Anti-patterns

- Do not edit CMakeLists.txt as a side effect of this review — only report. The file is a contract with downstream consumers; rewrites belong to a separate, explicit task.
- Do not flag `cmake_minimum_required(VERSION x)` as too low without checking what the project actually uses; bumping it changes default policies and may break the build.
- Do not recommend `FetchContent` over `find_package` blanketly. Source-builds add to the dependency surface and lengthen build times.
- Do not recommend `add_subdirectory(third_party/foo)` for libraries with their own CMake — it pollutes the parent project's options namespace.
- Do not ignore `set(CMAKE_BUILD_TYPE Release CACHE STRING ...)` if it is wrapped in an `if(NOT CMAKE_BUILD_TYPE)` guard — that's the canonical default-only idiom.
- Do not assume `target_link_libraries(<tgt> Foo::Foo)` is wrong because it omits `PUBLIC|PRIVATE|INTERFACE` — older CMake versions and some examples genuinely allow it, but flag it as MEDIUM for clarity.
- Do not flag custom commands (`add_custom_command`, `add_custom_target`) without reading what they do; many are essential code generators.
- Do not propose splitting one CMakeLists.txt into many subdirectory files unless the user asked for a refactor; that is scope creep.
- Do not recommend `cmake_policy(VERSION 3.x)` as a magic fix; it sets all policies up to 3.x to NEW, which can break a project that relied on OLD behavior of one of them.
- Do not flag `set(CMAKE_EXPORT_COMPILE_COMMANDS ON)` as bad — it is essential for clangd, clang-tidy, and IDEs.
- Do not require `BUILD_TESTING` gating in projects that are leaf applications (not libraries) — it adds friction without benefit.
- Do not suggest replacing `find_package(Threads REQUIRED)` + `Threads::Threads` with `-pthread`; the imported target is portable and correct.
- Do not silently approve `target_link_libraries(<tgt> -Wl,--no-undefined)` style raw linker flags without flagging that they are non-portable.
- Do not propose CMake presets (`CMakePresets.json`) unless the project is on CMake 3.21+ and the user asked for them.
