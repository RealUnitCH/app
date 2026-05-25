# Baseline Report

Run id: 20260525-215136
Role: Orchestrator
Date: 2026-05-25
Mode: DRY_RUN=true

## Safety Check

- Repository: `/Users/jk/DFXswiss/realunit-app`
- Git repository detected: yes
- Current branch: `joshua/all-initiatives`
- Protected branch gate: passed; branch is not `main`, `master`, `production`, or `release`
- Initial runner preflight: run-state says the runner checks the target repository is clean before the first role starts
- Current worktree before baseline: clean (`git status --porcelain=v1 -b` returned only the branch header)
- Merge/rebase/cherry-pick/revert state: absent
- Worktree after failed setup attempt: clean

## Overlay Compliance

- Checked project overlay paths by name: `CODEX_QUALITY_PROTOCOL.md`, `CODEX_MANDATE.md`, `AGENTS.md`, `.agents/AGENTS.md`, `.agents/global.md`, `CLAUDE.md`
- Result: no project overlay files were present
- Applied rule: cluster/run rules remain authoritative

## CI And Command Discovery

- `.github/workflows` is present.
- Workflow files found: `auto-release-pr.yaml`, `auto-tag.yaml`, `bitbox-simulator-slash.yml`, `bitbox-simulator.yml`, `handbook-deploy.yaml`, `handbook.yaml`, `maestro-bitbox.yaml`, `pull-request.yaml`, `release.yaml`, `tier3-handbook.yaml`
- Primary PR workflow: `.github/workflows/pull-request.yaml`
- PR workflow baseline commands:
  - `flutter pub get`
  - `dart run tool/generate_localization.dart`
  - `dart run tool/generate_release_info.dart`
  - `flutter pub run build_runner build`
  - `flutter analyze`
  - `flutter test --coverage`
- README test commands:
  - `flutter test`
  - `flutter test --coverage`
  - `flutter analyze`
- README setup commands:
  - `dart run tool/generate_localization.dart`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter pub get`
- Local tool discovery:
  - `flutter`: not found on PATH
  - `fvm`: `/opt/homebrew/bin/fvm`
  - `fvm flutter --version`: Flutter 3.41.9, Dart 3.11.5
- Version note: CI/README reference Flutter 3.41.6, while local FVM resolves 3.41.9.

## Commands Run

| Command | Exit | Evidence |
| --- | ---: | --- |
| `git rev-parse --is-inside-work-tree` | 0 | returned `true` |
| `git branch --show-current` | 0 | returned `joshua/all-initiatives` |
| `git status --porcelain=v1 -b` | 0 | one branch-header line only |
| `flutter --version` | 127 | `zsh:1: command not found: flutter` |
| `fvm flutter --version` | 0 | Flutter 3.41.9 / Dart 3.11.5 |
| `fvm flutter pub get` | 1 | failed before dependency resolution; log: `/var/folders/g1/8gzqb1vd2qxd0_k_lqr48vzr0000gn/T/ultra-pub-get.XXXXXX.log.mEFWsnXsVg` |

## Failed Setup Evidence

`fvm flutter pub get` emitted:

```text
[WARN] Failed to setup local cache. Falling back to git clone.
/Users/jk/fvm/versions/3.41.9/bin/internal/update_engine_version.sh: line 64: /Users/jk/fvm/versions/3.41.9/bin/cache/engine.stamp: Operation not permitted
```

This write target is outside the writable roots for the run. Approval policy is `never`, so the command cannot be retried with elevated filesystem permissions.

## Post-Run Elevated Diagnosis

After the agent stopped, the setup blocker was rechecked outside the role sandbox to distinguish sandbox noise from a real project blocker.

- A clean detached worktree was created at `/private/tmp/realunit-app-agent-20260525-215136`.
- Running the repo-level FVM command there failed because ignored `.fvm` / `.fvmrc` setup files are not present in the detached worktree.
- Running the explicit SDK binary `/Users/jk/fvm/versions/3.41.9/bin/flutter pub get` reached dependency resolution and failed with exit `69`.

The dependency failure was:

```text
Because realunit_wallet depends on bitbox_flutter from git which doesn't exist
(Could not find git ref 'joshua/i3-fake-inject-points' ...), version solving failed.
```

Evidence in `pubspec.yaml`:

```yaml
bitbox_flutter:
  git:
    url: https://github.com/joshuakrueger-dfx/bitbox_flutter.git
    ref: joshua/i3-fake-inject-points
```

Evidence in `pubspec.lock`:

```yaml
bitbox_flutter:
  dependency: "direct main"
  description:
    ref: "v0.0.7"
    resolved-ref: ebe0fb04e0fb1d56ae6fa815277598c980ac1940
    url: "https://github.com/DFXswiss/bitbox_flutter.git"
```

Local cross-repo evidence:

- `/Users/jk/DFXswiss/bitbox_flutter` has local branch commit `joshua/i3-fake-inject-points` at `944f79b9bd0f1101cc9d2d622e5e67455bcdc2cc`.
- `git ls-remote` against `https://github.com/joshuakrueger-dfx/bitbox_flutter.git refs/heads/joshua/i3-fake-inject-points` returned no remote ref.

Interpretation: the original sandbox failure is real for the agent role, but even with elevated filesystem access the project baseline is currently blocked by an unpublished or otherwise unavailable `bitbox_flutter` git ref. Analyzer, tests, and coverage cannot be trusted until dependency resolution is reproducible from a clean checkout.

## Commands Skipped

- `dart run tool/generate_localization.dart`: skipped because direct `dart` is not on PATH and the FVM Flutter SDK could not complete its setup check.
- `dart run tool/generate_release_info.dart`: skipped for the same reason.
- `flutter pub run build_runner build` / FVM equivalent: skipped because `pub get` failed before dependency resolution and build generation may modify tracked generated files.
- `flutter analyze`: skipped because the baseline environment is not executable.
- `flutter test --coverage`: skipped because the baseline environment is not executable.
- Coverage floor filtering/gate: skipped because no coverage artifact could be generated.
- Tier 2/Tier 3 workflows: skipped; they are conditional or simulator/hardware-oriented and are outside the Orchestrator baseline after the primary baseline failed.

## Local Setup Artifacts

- No accepted local setup artifacts were created.
- Git remained clean after the failed `fvm flutter pub get` attempt.
- No tracked source, test, lockfile, migration, CI, or secret files were modified.

## Baseline Interpretation

Baseline is blocked before analyzer/tests can run.

The agent role itself correctly stopped on the sandbox/FVM cache write failure. A follow-up elevated setup attempt then exposed the CI-relevant blocker: `pub get` cannot resolve the `bitbox_flutter` git branch referenced by `pubspec.yaml` from a clean checkout.

Gate 1 is not satisfied because CI-adjacent baseline commands could not be executed. Per the run instructions and Gate 1 stop rule, the run must stop safely.

## Known Limits

- No analyzer, unit/widget tests, coverage run, coverage floor gate, simulator flow, or build validation completed.
- The baseline report does not establish whether the project passes CI.
- The local Flutter version discovered through FVM differs from the CI/README version reference.
- `pubspec.yaml` and `pubspec.lock` currently point at different `bitbox_flutter` sources/refs.
- The local `bitbox_flutter` branch exists, but it was not available from the configured GitHub remote during verification.
- The temp command log path is outside the repository and may be ephemeral.
