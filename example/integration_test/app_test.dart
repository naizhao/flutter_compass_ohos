import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_compass_example/main.dart' as app;

/// 集成测试驱动文件
///
/// 用于运行应用级别的集成测试
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('应用集成测试', () {
    testWidgets('应用能够正常启动和运行', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 验证应用已启动
      expect(find.text('Flutter Compass'), findsOneWidget);

      print('✓ 应用启动成功');
    });
  });
}
