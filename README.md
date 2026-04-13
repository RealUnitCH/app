# Real Unit App

A Flutter Wallet for Real Unit Investors.

## Getting Started

Before getting started, please make sure you have Flutter version 3.38.7 and the latest version of golang and gomobile installed.

```shell
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

### 1. Set up environment variables

Copy the example env file and fill in your API keys:

```shell
cp .env.example .env
```

`.env` is gitignored. The required keys are:

```
ALCHEMY_API_KEY=your_alchemy_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 3. Generate translations

```shell
dart run tool/generate_localization.dart
```

### 4. Generate Drift Files

```shell
dart run build_runner build --delete-conflicting-outputs
```

### 5. Get dependencies

```shell
flutter pub get
```

### 6. Start app

```shell
flutter run
```
