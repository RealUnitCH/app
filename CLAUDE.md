# RealUnit App — Claude Code Guidelines

## Build & Test Commands

```bash
flutter pub get
dart run tool/generate_localization.dart   # generate i18n from ARB files
flutter pub run build_runner build          # generate code (drift, etc.)
flutter test                                # run all tests
flutter analyze                             # lint check
```

After changing ARB files, always regenerate: `dart run tool/generate_localization.dart`

## Project Architecture

```
lib/
  di.dart                          # GetIt service locator setup
  router.dart                      # GoRouter route definitions
  models/                          # Domain models (extend Equatable)
  packages/
    repository/                    # Data access layer
    service/dfx/
      models/{resource}/dto/       # DTOs with fromJson()
      {resource}_service.dart      # Business logic services
  screens/{screen}/
    bloc/ or cubits/               # State management per screen
    widgets/                       # Screen-specific widgets
  styles/                          # Colors, TextStyles, Themes
  widgets/                         # Shared reusable widgets
```

## Styling — CRITICAL

- **Colors**: Always use `RealUnitColors.*` or `RealUnitColors.basic.white` / `.black`. NEVER use `Colors.white`, `Colors.black`, or raw `Color(0x...)` values.
- **Transparent colors**: `RealUnitColors.basic.white.withValues(alpha: 0)` — NEVER `Color(0x00FFFFFF)` or `Colors.transparent`.
- **TextStyles**: Always use `Theme.of(context).textTheme.*` (headlineLarge/Medium/Small, bodyLarge/Medium/Small). NEVER hardcode `TextStyle(fontSize: 26, fontWeight: ...)`.
  - Mapping: `headlineLarge` = h1 (30/600), `headlineMedium` = h2 (26/bold), `headlineSmall` = h4 (20/bold), `bodyLarge` = base (16), `bodyMedium` = sm (14), `bodySmall` = xs (12)
  - Add color via `.copyWith(color: RealUnitColors.neutral500)`.
- **Loading indicators**: `CupertinoActivityIndicator` — NEVER `CircularProgressIndicator`.
- **Formatter**: Page width 100, trailing commas preserved. Single quotes required.

## Localization (i18n)

- Source files: `assets/languages/strings_de.arb` and `strings_en.arb`
- Generated file: `lib/generated/i18n.dart` (in .gitignore)
- Keys MUST be alphabetically sorted in both ARB files.
- Always update BOTH de and en ARB files.
- Punctuation belongs in the template (`'${s.label}: $value'`), NOT in the ARB value.
- Before adding a new key: search existing keys first — reuse where possible.
- NEVER use `S.current` (no context) in cubits/blocs. Instead, emit a typed state and let the UI resolve localization via `S.of(context)`.

## State Management

- **Bloc**: For complex event-driven flows. Events are `sealed class` extending `Equatable`. States use `final class` with `copyWith`.
- **Cubit**: For simpler state. States extend `Equatable` with `copyWith`.
- State files are separate from bloc/cubit files.
- Validation logic belongs in the cubit/bloc, NOT in the widget tree.

## DTOs & Models

- DTOs live in `lib/packages/service/dfx/models/{resource}/dto/`
- Naming: `{Resource}Dto` with `factory fromJson(Map<String, dynamic> json)`
- Type casting: `json['field'] as Type` — no dynamic access.
- NEVER parse JSON inline in services — always create a DTO class.
- Domain models are separate from DTOs and extend `Equatable`.

## Navigation

- Uses GoRouter. Routes defined in `lib/router.dart`.
- Pages should read their own dependencies from Bloc/DI — avoid passing data via route `extra` when the page can obtain it from context.

## Dependency Injection

- GetIt service locator in `lib/di.dart`.
- Access via `getIt<ServiceType>()` — use inline, don't store in local variables unless used multiple times.

## Testing

- Uses `flutter_test`, `bloc_test`, and `mocktail` (NOT mockito).
- Test structure mirrors `lib/` structure.
- Test helper at `test/helper/` (provides `pumpApp`).

## Widget Guidelines

- Prefer `StatelessWidget` unless lifecycle management is truly needed.
- Extract widgets into own files when they exceed ~30 lines of build logic.
- Don't create wrapper widgets that only delegate to a child.
- Use `Align` instead of `Positioned` when only alignment is needed.

## Dependencies

- `pubspec.yaml` dependencies must be alphabetically sorted.
- Imports within files: alphabetically sorted. Order: `dart:` → `package:flutter` → `package:other` → `package:realunit_wallet/`.

## Common Mistakes to Avoid

- Don't leave unused imports after refactoring.
- Don't use default parameter values that contradict business rules (e.g., `amount = '300'` when minimum is 1000).
- Don't add explanatory comments for workarounds — fix the root cause instead.
