# Rateify

Rateify is a seamless multi-currency calculator inspired by the simplicity of the iOS Calculator experience. It lets users convert an amount across multiple currencies instantly, understand converted prices through user-defined real-world benchmarks, track trip budgets and expenses in a local trip currency, set rate alerts for currency pairs, and view lightweight historical rate trends — all offline-first, with no account required.

## Architecture

Feature-first architecture with the Repository Pattern and Riverpod for state management. Each feature under `lib/features/` is split into `domain/` (entities, repository interfaces, calculators/services, use cases), `data/` (datasources, models, repository implementations), and `presentation/` (providers, pages, widgets). Shared, feature-agnostic code lives in `lib/core/` (constants, error types, number/currency formatting, theme, utilities).

Presentation-layer code never imports `dio` or `hive` directly — all remote/local data access goes through a repository.

## Getting Started

Requires the Flutter stable channel (see `.github/workflows/ci.yaml` for the exact version this project is built against).

```bash
flutter pub get
flutter run -d chrome   # or: flutter run -d macos
```

## Running Tests

```bash
flutter analyze
flutter test
```

CI runs both of the above (plus a formatting check) on every push and pull request.
