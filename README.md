# Real Unit App

A Flutter Wallet for Real Unit Investors.

## Getting Started

Before getting started, please make sure you have Flutter version 3.38.7 and the latest version of golang and gomobile installed.

```shell
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

### 1. Generate translations

```shell
dart run tool/generate_localization.dart
```

### 2. Generate Drift Files

```shell
dart run build_runner build --delete-conflicting-outputs
```

### 3. Get dependencies

```shell
flutter pub get
```

### 3. Start app

```shell
flutter run
```
