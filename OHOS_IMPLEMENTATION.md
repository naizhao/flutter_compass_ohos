# Flutter Compass 鸿蒙平台实施文档

## 📋 实施概述

本文档记录了 flutter_compass 插件的鸿蒙（OpenHarmony/HarmonyOS）平台适配过程。

**实施方式**：直接集成（Platform Channel - EventChannel）
**实施日期**：2025-10-18
**实施状态**：✅ 已完成

---

## 🎯 实施方案选择

### 为什么选择直接集成？

1. **插件架构匹配**：flutter_compass 是传统非联合插件，所有平台代码在同一包内
2. **保持一致性**：与 Android/iOS 实现方式保持一致
3. **简单高效**：无需复杂的项目架构改造
4. **易于维护**：代码集中，便于后续更新

### 技术方案

- **通信方式**：EventChannel（适合持续的传感器数据流）
- **传感器 API**：`@ohos.sensor` - 方向传感器（ORIENTATION）
- **备用方案**：旋转矢量传感器（ROTATION_VECTOR）
- **数据格式**：`[heading, cameraHeading, accuracy]` 与 iOS/Android 保持一致

---

## 📁 创建的文件结构

```
ohos/
├── oh-package.json5                          # 鸿蒙包配置文件
├── src/
│   └── main/
│       ├── ets/
│       │   ├── Index.ets                     # 插件入口
│       │   └── components/
│       │       └── plugin/
│       │           └── FlutterCompassPlugin.ets  # 核心插件实现
│       ├── module.json5                      # 模块配置（权限等）
│       └── resources/
│           └── base/
│               ├── element/
│               │   └── string.json           # 权限说明文本
│               └── profile/
│                   └── main_pages.json       # 页面配置
```

---

## 🔧 核心实现

### 1. pubspec.yaml 配置

```yaml
flutter:
  plugin:
    platforms:
      ohos:
        packageName: com.hemanthraj.fluttercompass
        pluginClass: FlutterCompassPlugin
```

### 2. 传感器实现要点

#### 方向传感器数据
- 使用 `sensor.SensorId.ORIENTATION`
- 返回数据：`alpha`（z轴旋转，即指南针方向 0-360°）
- 更新频率：100ms

#### 数据处理
- **平滑处理**：使用低通滤波器（ALPHA=0.45）避免抖动
- **边界处理**：正确处理 0/360° 边界跳变
- **精度映射**：统一返回精度值 15（高精度）

#### 备用方案
- 如果方向传感器不可用，自动切换到旋转矢量传感器
- 通过四元数转欧拉角计算方位

### 3. 权限配置

在 `module.json5` 中声明：
```json
{
  "name": "ohos.permission.ACCELEROMETER",
  "reason": "Access to compass and orientation sensors",
  "usedScene": {
    "abilities": ["MainAbility"],
    "when": "inuse"
  }
}
```

---

## 🚀 如何测试

### 环境要求

1. **Flutter SDK**：鸿蒙版 Flutter SDK（3.22.0+）
2. **开发工具**：DevEco Studio 4.0+
3. **测试设备**：
   - 鸿蒙真机（推荐，有真实传感器）
   - 鸿蒙模拟器（可能没有传感器支持）

### 测试步骤

#### 方式一：使用现有 example（推荐）

```bash
# 1. 进入 example 目录
cd example

# 2. 如果没有 ohos 平台，添加它
flutter create --platforms ohos .

# 3. 获取依赖
flutter pub get

# 4. 连接鸿蒙设备

# 5. 运行
flutter run
```

#### 方式二：创建新的测试应用

```bash
# 1. 创建新的 Flutter 应用
flutter create --platforms ohos compass_test
cd compass_test

# 2. 添加插件依赖（在 pubspec.yaml）
dependencies:
  flutter_compass:
    path: ../  # 指向 flutter_compass 目录

# 3. 运行
flutter run
```

### 测试用例

- [ ] 应用启动正常
- [ ] 能够成功获取指南针数据
- [ ] 数据流持续更新（每 100ms）
- [ ] 旋转设备时数据正确变化
- [ ] 数值在 0-360 度范围内
- [ ] 无明显抖动（已平滑处理）
- [ ] 后台返回前台数据恢复正常

---

## 📝 使用说明

### 基本使用

```dart
import 'package:flutter_compass/flutter_compass.dart';

// 监听指南针数据流
FlutterCompass.events?.listen((CompassEvent event) {
  double? heading = event.heading;
  double? accuracy = event.accuracy;

  print('Heading: $heading°, Accuracy: $accuracy');
});
```

### 鸿蒙权限处理

在鸿蒙平台上，传感器权限通常自动授予，无需运行时请求。但建议：

1. 检查传感器是否可用：
```dart
FlutterCompass.events?.listen((event) {
  if (event.heading == null) {
    // 传感器不可用或无权限
  }
});
```

2. 处理错误情况：
```dart
FlutterCompass.events?.handleError((error) {
  print('Compass error: $error');
});
```

---

## ⚠️ 注意事项

### 1. 传感器可用性

- 并非所有鸿蒙设备都有方向传感器
- 模拟器可能不支持传感器模拟
- 如果传感器不可用，会自动尝试旋转矢量传感器
- 若都不可用，会通过 EventChannel 返回错误

### 2. 精度说明

- 鸿蒙返回的精度值固定为 15（表示高精度）
- 实际精度取决于硬件传感器质量
- 在高磁场干扰环境下精度可能降低

### 3. 电池优化

- 传感器持续监听会消耗电量
- 建议在不需要时取消监听：
```dart
StreamSubscription? _compassSubscription;

// 开始监听
_compassSubscription = FlutterCompass.events?.listen(...);

// 停止监听
_compassSubscription?.cancel();
```

### 4. 数据平滑

- 已内置低通滤波器，无需应用层再次平滑
- 如需调整平滑程度，修改 `ALPHA` 值（0.45）

---

## 🔍 故障排查

### 问题 1：编译失败

**症状**：构建时报错找不到模块

**解决方案**：
```bash
# 清理构建缓存
flutter clean
cd ohos
rm -rf build oh_modules
cd ..

# 重新获取依赖
flutter pub get

# 重新构建
flutter build ohos
```

### 问题 2：传感器无数据

**症状**：应用运行正常但 heading 始终为 null

**可能原因**：
1. 设备没有方向传感器
2. 权限未授予
3. 传感器被其他应用占用

**解决方案**：
- 检查设备传感器列表
- 在真机上测试（非模拟器）
- 重启设备后重试

### 问题 3：数据抖动严重

**症状**：heading 值跳动频繁

**解决方案**：
- 增大平滑系数 ALPHA（当前 0.45，可改为 0.6-0.8）
- 远离强磁场干扰源
- 执行设备指南针校准（8字形晃动）

---

## 📊 与其他平台对比

| 特性 | Android | iOS | HarmonyOS |
|------|---------|-----|-----------|
| 传感器类型 | ROTATION_VECTOR / ACCELEROMETER + MAGNETIC_FIELD | CLLocationManager + CMMotionManager | ORIENTATION / ROTATION_VECTOR |
| 更新频率 | 30ms | ~33ms | 100ms |
| 精度级别 | 15/30/45/-1 | 动态精度 | 15（固定） |
| 平滑处理 | ✅ | ✅ | ✅ |
| 设备方向补偿 | ✅ | ✅ | ✅ |

---

## 🎉 总结

### 已完成

- ✅ pubspec.yaml 配置 ohos 平台
- ✅ 创建完整 ohos 目录结构
- ✅ 实现 FlutterCompassPlugin.ets
- ✅ 配置权限和资源文件
- ✅ 数据格式与 iOS/Android 保持一致
- ✅ 实现平滑处理和错误处理
- ✅ 添加备用传感器方案

### 待测试

- ⏳ 在鸿蒙真机上验证功能
- ⏳ 测试不同设备型号兼容性
- ⏳ 性能和电量消耗测试

### 后续优化

- 🔄 根据测试结果调整平滑参数
- 🔄 添加设备校准提示
- 🔄 优化传感器切换逻辑

---

## 📚 参考资料

- [鸿蒙 Flutter 开发文档](https://gitee.com/openharmony-sig/flutter_flutter)
- [鸿蒙传感器 API](https://developer.huawei.com/consumer/cn/doc/harmonic-references-V5/js-apis-sensor-V5)
- [Flutter Plugin 开发](https://docs.flutter.dev/packages-and-plugins/developing-packages)

---

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- GitHub Issues: [flutter_compass/issues](https://github.com/hemanthrajv/flutter_compass/issues)
- 原作者: hemanthraj
- 鸿蒙适配: [Sam NG]

---

**最后更新时间**: 2025-10-18
