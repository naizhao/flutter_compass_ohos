# flutter_compass

[![pub package](https://img.shields.io/pub/v/flutter_compass.svg)](https://pub.dartlang.org/packages/flutter_compass)

A Flutter compass. The heading varies from 0-360, 0 being north.


_Note:_
_Android Only: `null` is returned as direction on android when no sensor available._

## Usage

To use this plugin, add `flutter_compass` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  flutter_compass: '^0.8.1'
```

### iOS
Make sure to add keys with appropriate descriptions to the `Info.plist` file.

* `NSLocationWhenInUseUsageDescription`
* `NSLocationAlwaysAndWhenInUseUsageDescription`

:memo: [Reference example code](https://github.com/hemanthrajv/flutter_compass/blob/89dccd39a32af970322b237e574d2e6fa3454568/example/ios/Runner/Info.plist#L27-L30)

### Android
Make sure to add permissions to the `app/src/main/AndroidManifest.xml` file.

* `android.permission.INTERNET`
* `android.permission.ACCESS_COARSE_LOCATION`
* `android.permission.ACCESS_FINE_LOCATION`

:memo: [Reference example code](https://github.com/hemanthrajv/flutter_compass/blob/89dccd39a32af970322b237e574d2e6fa3454568/example/android/app/src/main/AndroidManifest.xml#L4-L10)

### HarmonyOS (OpenHarmony)
The plugin now supports HarmonyOS! Permissions are configured in `module.json5`:

* `ohos.permission.ACCELEROMETER` - Required for accessing compass sensor

The permission is automatically included in the plugin configuration. For detailed implementation information, see [OHOS_IMPLEMENTATION.md](OHOS_IMPLEMENTATION.md).

**Note:**
- Requires HarmonyOS Flutter SDK 3.22.0+
- Sensor data uses ORIENTATION or ROTATION_VECTOR sensor
- Returns `null` if no compass sensor is available on the device

### Recommended support plugins

* [Flutter Permission handler Plugin](https://github.com/Baseflow/flutter-permission-handler): Easy to request and check permissions in a cross-platform (iOS, Android) API.

:memo: [Reference example code](https://github.com/hemanthrajv/flutter_compass/blob/89dccd39a32af970322b237e574d2e6fa3454568/example/pubspec.yaml#L12)
