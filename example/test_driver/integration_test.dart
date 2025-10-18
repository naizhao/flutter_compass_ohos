import 'package:integration_test/integration_test_driver.dart';

/// 集成测试驱动程序
///
/// 用于运行集成测试的驱动文件
/// 使用方法：
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/compass_ohos_test.dart
Future<void> main() => integrationDriver();
