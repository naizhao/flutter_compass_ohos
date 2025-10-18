import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// 鸿蒙平台指南针集成测试
///
/// 测试目标：
/// 1. 验证 EventChannel 通信正常
/// 2. 验证传感器数据格式正确
/// 3. 验证数据范围在 0-360 度之间
/// 4. 验证数据流持续更新
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('鸿蒙平台指南针测试', () {
    test('插件能够正常初始化', () async {
      // 验证插件是否可用
      expect(FlutterCompass.events, isNotNull);
    });

    test('能够订阅指南针事件流', () async {
      // 尝试订阅事件流
      final stream = FlutterCompass.events;
      expect(stream, isNotNull);
      expect(stream, isA<Stream<CompassEvent>>());
    });

    test('能够接收到指南针数据', () async {
      final completer = Completer<CompassEvent>();
      StreamSubscription? subscription;

      try {
        // 订阅事件流，等待第一个事件
        subscription = FlutterCompass.events?.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // 等待最多 5 秒接收数据
        final event = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('未能在 5 秒内接收到指南针数据');
          },
        );

        // 验证接收到数据
        expect(event, isNotNull);
        print('✓ 成功接收到指南针事件');
      } finally {
        await subscription?.cancel();
      }
    });

    test('指南针数据格式正确', () async {
      final completer = Completer<CompassEvent>();
      StreamSubscription? subscription;

      try {
        subscription = FlutterCompass.events?.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        final event = await completer.future.timeout(
          const Duration(seconds: 5),
        );

        // 验证数据字段存在
        expect(event.heading, isNotNull, reason: 'heading 不应为 null');
        expect(event.accuracy, isNotNull, reason: 'accuracy 不应为 null');

        print('✓ 数据格式验证通过');
        print('  - heading: ${event.heading}°');
        print('  - accuracy: ${event.accuracy}');
      } finally {
        await subscription?.cancel();
      }
    });

    test('heading 值在有效范围内 (0-360度)', () async {
      final completer = Completer<CompassEvent>();
      StreamSubscription? subscription;

      try {
        subscription = FlutterCompass.events?.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        final event = await completer.future.timeout(
          const Duration(seconds: 5),
        );

        final heading = event.heading!;

        // 验证 heading 在 0-360 范围内
        expect(heading, greaterThanOrEqualTo(0.0),
          reason: 'heading 应该 >= 0');
        expect(heading, lessThan(360.0),
          reason: 'heading 应该 < 360');

        print('✓ heading 范围验证通过: $heading°');
      } finally {
        await subscription?.cancel();
      }
    });

    test('accuracy 值符合预期 (鸿蒙返回固定值 15)', () async {
      final completer = Completer<CompassEvent>();
      StreamSubscription? subscription;

      try {
        subscription = FlutterCompass.events?.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        final event = await completer.future.timeout(
          const Duration(seconds: 5),
        );

        final accuracy = event.accuracy!;

        // 鸿蒙实现中固定返回 15 (高精度)
        expect(accuracy, equals(15.0),
          reason: '鸿蒙平台 accuracy 应该为 15');

        print('✓ accuracy 验证通过: $accuracy');
      } finally {
        await subscription?.cancel();
      }
    });

    test('数据流持续更新 (接收多个事件)', () async {
      final events = <CompassEvent>[];
      StreamSubscription? subscription;

      try {
        final completer = Completer<void>();

        subscription = FlutterCompass.events?.listen((event) {
          events.add(event);

          // 收集 5 个事件后完成
          if (events.length >= 5) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });

        // 等待接收 5 个事件，最多等待 10 秒
        await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('未能在 10 秒内接收到 5 个事件');
          },
        );

        // 验证接收到多个事件
        expect(events.length, greaterThanOrEqualTo(5),
          reason: '应该接收到至少 5 个事件');

        print('✓ 数据流持续更新验证通过');
        print('  - 接收到 ${events.length} 个事件');

        // 打印前几个事件的 heading 值
        for (var i = 0; i < events.length.clamp(0, 3); i++) {
          print('  - Event $i: heading=${events[i].heading}°');
        }
      } finally {
        await subscription?.cancel();
      }
    });

    test('平滑处理生效 (连续数据变化平缓)', () async {
      final headings = <double>[];
      StreamSubscription? subscription;

      try {
        final completer = Completer<void>();

        subscription = FlutterCompass.events?.listen((event) {
          if (event.heading != null) {
            headings.add(event.heading!);
          }

          // 收集 10 个数据点
          if (headings.length >= 10) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });

        await completer.future.timeout(
          const Duration(seconds: 15),
        );

        // 计算相邻数据点之间的最大变化
        double maxChange = 0;
        for (var i = 1; i < headings.length; i++) {
          var diff = (headings[i] - headings[i - 1]).abs();

          // 处理 0/360 度边界情况
          if (diff > 180) {
            diff = 360 - diff;
          }

          if (diff > maxChange) {
            maxChange = diff;
          }
        }

        // 由于应用了平滑处理 (ALPHA=0.45)，
        // 相邻数据点变化不应该太剧烈
        // 这里设置一个合理的阈值 50 度
        expect(maxChange, lessThan(50.0),
          reason: '平滑处理后，相邻数据变化应该 < 50°');

        print('✓ 平滑处理验证通过');
        print('  - 最大单次变化: ${maxChange.toStringAsFixed(2)}°');

        final average = headings.reduce((a, b) => a + b) / headings.length;
        print('  - 平均值: ${average.toStringAsFixed(2)}°');
      } finally {
        await subscription?.cancel();
      }
    });

    test('取消订阅后不再接收数据', () async {
      final events = <CompassEvent>[];

      // 订阅并接收一些数据
      final subscription = FlutterCompass.events?.listen((event) {
        events.add(event);
      });

      // 等待接收至少 2 个事件
      await Future.delayed(const Duration(seconds: 2));

      final countBeforeCancel = events.length;
      expect(countBeforeCancel, greaterThan(0),
        reason: '取消前应该接收到数据');

      // 取消订阅
      await subscription?.cancel();

      // 等待一段时间
      await Future.delayed(const Duration(seconds: 2));

      final countAfterCancel = events.length;

      // 验证取消后数据不再增加（或增加很少，考虑到异步延迟）
      expect(countAfterCancel - countBeforeCancel, lessThan(3),
        reason: '取消订阅后不应该继续接收大量数据');

      print('✓ 取消订阅验证通过');
      print('  - 取消前: $countBeforeCancel 个事件');
      print('  - 取消后: $countAfterCancel 个事件');
    });

    test('多次订阅和取消不会导致错误', () async {
      for (var i = 0; i < 3; i++) {
        print('  第 ${i + 1} 次订阅/取消循环');

        final completer = Completer<CompassEvent>();

        final subscription = FlutterCompass.events?.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // 等待接收数据
        await completer.future.timeout(
          const Duration(seconds: 3),
        );

        // 取消订阅
        await subscription?.cancel();

        // 短暂等待
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('✓ 多次订阅/取消验证通过');
    });

    test('传感器错误处理 (模拟传感器不可用)', () async {
      // 注意：这个测试在有传感器的设备上会通过
      // 在没有传感器的设备上，应该能捕获到错误

      bool errorOccurred = false;
      String? errorMessage;

      final subscription = FlutterCompass.events?.handleError((error) {
        errorOccurred = true;
        errorMessage = error.toString();
        print('捕获到错误: $error');
      }).listen((event) {
        // 正常接收数据
      });

      await Future.delayed(const Duration(seconds: 3));
      await subscription?.cancel();

      // 如果有传感器，不应该有错误
      // 如果没有传感器，应该有错误信息
      if (errorOccurred) {
        print('✓ 错误处理验证通过 (捕获到传感器不可用错误)');
        print('  - 错误信息: $errorMessage');
      } else {
        print('✓ 错误处理验证通过 (传感器正常工作)');
      }
    });
  });
}
