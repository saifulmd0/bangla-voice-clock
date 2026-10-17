# Bangla Voice Clock

A free talking clock that announces the time in Bangla. macOS first, other platforms later.

Inspired by the original *Bangla Voice Clock* for Windows (1998–2002) by Q A M Khaled Ferdaus.

> **Status:** early development. See [docs/PLAN.md](docs/PLAN.md) for the full plan.

## Download (development builds)

Every push to `main` builds the macOS app on GitHub Actions.

1. Open the [Actions tab](../../actions), pick the latest successful **CI** run.
2. Download **BanglaVoiceClock-macos** from the Artifacts section and unzip it.
3. These builds are not signed yet. The first time, right-click the app and choose **Open**.

## Development

Requires [Flutter](https://flutter.dev) 3.47.

```sh
flutter pub get
flutter test      # runs without Xcode
flutter analyze
```

Building and running the macOS app locally (`flutter run -d macos`) also needs Xcode.
Without Xcode, push to GitHub and let CI build it.
