# Flutter Compass 鸿蒙平台集成测试

## 📋 概述

此目录包含 flutter_compass 插件在鸿蒙（HarmonyOS/OpenHarmony）平台上的集成测试。

## 🧪 测试文件

### 1. `compass_ohos_test.dart`
鸿蒙平台指南针功能的完整集成测试。

**测试覆盖：**
- ✅ 插件初始化
- ✅ EventChannel 通信
- ✅ 传感器数据接收
- ✅ 数据格式验证
- ✅ 数据范围验证 (0-360度)
- ✅ 精度值验证 (固定值 15)
- ✅ 数据流持续更新
- ✅ 平滑处理算法
- ✅ 订阅/取消机制
- ✅ 错误处理

### 2. `app_test.dart`
应用级别集成测试，验证整体应用功能。

## 🚀 运行测试

### 前置要求

1. **Flutter SDK**: 鸿蒙版 Flutter SDK (3.22.0+)
2. **开发工具**: DevEco Studio 4.0+
3. **测试设备**:
   - 鸿蒙真机（推荐，有真实传感器）
   - 鸿蒙模拟器（可能不支持传感器）

### 环境准备

```bash
# 1. 进入 example 目录
cd example

# 2. 确保已添加鸿蒙平台
flutter create --platforms ohos .

# 3. 安装依赖
flutter pub get
```

### 运行全部集成测试

```bash
# 连接鸿蒙设备后运行
flutter test integration_test/compass_ohos_test.dart
```

### 运行特定测试

```bash
# 只运行特定的测试组
flutter test integration_test/compass_ohos_test.dart --name "指南针数据格式正确"
```

### 在真机上运行

```bash
# 1. 连接鸿蒙真机
flutter devices  # 确认设备已连接

# 2. 运行集成测试（带设备显示）
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/compass_ohos_test.dart \
  -d <device-id>
```

### 创建测试驱动（如需要）

如果需要使用 `flutter drive` 命令，创建 `test_driver/integration_test.dart`:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

## 📊 测试说明

### 测试 1: 插件能够正常初始化
验证 `FlutterCompass.events` 不为 null。

### 测试 2: 能够订阅指南针事件流
验证可以成功订阅 Stream<CompassEvent>。

### 测试 3: 能够接收到指南针数据
在 5 秒内至少接收到一个有效的指南针事件。

### 测试 4: 指南针数据格式正确
验证 `CompassEvent` 包含必需字段：
- `heading`: 方向角度
- `accuracy`: 精度值

### 测试 5: heading 值在有效范围内
验证 `heading` 在 [0, 360) 范围内。

### 测试 6: accuracy 值符合预期
验证鸿蒙平台返回固定精度值 15（高精度）。

### 测试 7: 数据流持续更新
验证在 10 秒内能够接收到至少 5 个事件（约 100ms 间隔）。

### 测试 8: 平滑处理生效
验证低通滤波器工作正常，相邻数据点变化平缓（< 50°）。

### 测试 9: 取消订阅后不再接收数据
验证调用 `subscription.cancel()` 后数据流停止。

### 测试 10: 多次订阅和取消不会导致错误
验证插件的生命周期管理正确。

### 测试 11: 传感器错误处理
验证在传感器不可用时能够正确捕获和处理错误。

## ⚠️ 注意事项

### 1. 传感器依赖
- 测试需要真实的方向传感器或旋转矢量传感器
- 在模拟器上运行可能导致部分测试失败
- 建议在鸿蒙真机上运行测试

### 2. 测试超时
某些测试设置了超时限制：
- 单个事件接收: 5 秒
- 多个事件接收: 10-15 秒

如果设备传感器响应慢，可能需要调整超时时间。

### 3. 环境因素
传感器精度受环境影响：
- 强磁场干扰会影响测试结果
- 移动设备时测试更容易通过
- 静止时数据可能变化较小

### 4. 权限要求
鸿蒙平台访问传感器需要 `ohos.permission.ACCELEROMETER` 权限（已在 `module.json5` 中配置）。

## 🔍 故障排查

### 问题 1: 测试全部失败
**可能原因**: 设备没有传感器或传感器不可用

**解决方案**:
- 在真机上运行测试
- 检查设备传感器列表
- 确认权限已授予

### 问题 2: 超时错误
**可能原因**: 传感器响应慢或未启动

**解决方案**:
- 增加超时时间
- 重启设备
- 检查是否有其他应用占用传感器

### 问题 3: 数据抖动测试失败
**可能原因**: 环境磁场干扰或设备剧烈晃动

**解决方案**:
- 远离强磁场源（如磁铁、电机）
- 测试时保持设备相对静止
- 调整平滑处理阈值（在测试代码中）

### 问题 4: accuracy 值不是 15
**可能原因**: 实现代码与测试预期不符

**解决方案**:
- 检查 `FlutterCompassPlugin.ets` 中的 accuracy 返回值
- 确认返回格式为 `[heading, heading, 15.0]`

## 📈 测试报告

运行测试后，查看控制台输出了解测试结果：

```bash
✓ 成功接收到指南针事件
✓ 数据格式验证通过
  - heading: 123.45°
  - accuracy: 15.0
✓ heading 范围验证通过: 123.45°
✓ accuracy 验证通过: 15.0
✓ 数据流持续更新验证通过
  - 接收到 5 个事件
...
```

## 📚 参考资料

- [Flutter 集成测试文档](https://docs.flutter.dev/testing/integration-tests)
- [鸿蒙 Flutter 开发指南](https://gitee.com/openharmony-sig/flutter_flutter)
- [OHOS_IMPLEMENTATION.md](../OHOS_IMPLEMENTATION.md) - 鸿蒙实现详解

## 🤝 贡献

如果发现测试问题或有改进建议，欢迎提交 Issue 或 Pull Request。

---

**最后更新**: 2025-10-18
