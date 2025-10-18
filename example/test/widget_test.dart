import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_compass_example/main.dart';

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('应用能够正常构建', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());

      // 验证应用能够正常加载
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('AppBar 显示正确的标题', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 验证 AppBar 标题
      expect(find.text('Flutter Compass'), findsOneWidget);
    });

    testWidgets('权限请求界面显示正确的元素', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 验证权限请求界面的文本和按钮
      expect(find.text('Location Permission Required'), findsOneWidget);
      expect(find.text('Request Permissions'), findsOneWidget);
      expect(find.text('Open App Settings'), findsOneWidget);
    });

    testWidgets('权限请求按钮可以点击', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 查找并点击 Request Permissions 按钮
      final requestButton = find.text('Request Permissions');
      expect(requestButton, findsOneWidget);

      // 验证按钮可以被点击
      await tester.tap(requestButton);
      await tester.pump();
    });

    testWidgets('应用设置按钮可以点击', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 查找并点击 Open App Settings 按钮
      final settingsButton = find.text('Open App Settings');
      expect(settingsButton, findsOneWidget);

      // 验证按钮可以被点击
      await tester.tap(settingsButton);
      await tester.pump();
    });

    testWidgets('Scaffold 存在于 widget 树中', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 验证 Scaffold 存在
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('AppBar 存在于 widget 树中', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(MyApp());
      await tester.pump();

      // 验证 AppBar 存在
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
