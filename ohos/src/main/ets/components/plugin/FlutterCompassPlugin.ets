/*
 * Flutter Compass Plugin for HarmonyOS
 * Uses orientation sensor to get compass heading
 */

import sensor from '@ohos.sensor';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import EventChannel, {
  EventSink,
  StreamHandler
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodResult, MethodCallHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';

const CHANNEL_NAME = "hemanthraj/flutter_compass";
const TAG = "FlutterCompass";

// 传感器更新间隔（毫秒）
const SENSOR_UPDATE_INTERVAL = 100000000; // 100ms in nanoseconds

export class FlutterCompassPlugin implements FlutterPlugin, StreamHandler {
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;

  // 上次方向角度
  private lastHeading: number = 0;

  constructor() {
    console.info(TAG, 'FlutterCompassPlugin constructor called');
  }

  /**
   * Plugin 附加到 Flutter 引擎时调用
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    console.info(TAG, 'onAttachedToEngine called');
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this);
  }

  /**
   * Plugin 从 Flutter 引擎分离时调用
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    console.info(TAG, 'onDetachedFromEngine called');
    if (this.eventChannel != null) {
      this.eventChannel.setStreamHandler(null);
      this.eventChannel = null;
    }
    this.unregisterSensor();
  }

  /**
   * 开始监听传感器数据流
   */
  onListen(args: ESObject, sink: EventSink): void {
    console.info(TAG, 'onListen called');
    this.eventSink = sink;
    this.registerSensor();
  }

  /**
   * 取消监听传感器数据流
   */
  onCancel(args: ESObject): void {
    console.info(TAG, 'onCancel called');
    this.unregisterSensor();
    this.eventSink = null;
  }

  /**
   * 注册传感器监听
   */
  private registerSensor(): void {
    try {
      console.info(TAG, 'Registering orientation sensor');

      // 监听方向传感器
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        this.onSensorChanged(data);
      }, { interval: SENSOR_UPDATE_INTERVAL });

      console.info(TAG, 'Orientation sensor registered successfully');
    } catch (error) {
      console.error(TAG, `Failed to register sensor: ${error.message}`);
      // 如果方向传感器不可用，尝试使用旋转矢量传感器
      this.tryRegisterRotationVector();
    }
  }

  /**
   * 尝试注册旋转矢量传感器（备用方案）
   */
  private tryRegisterRotationVector(): void {
    try {
      console.info(TAG, 'Trying rotation vector sensor as fallback');

      sensor.on(sensor.SensorId.ROTATION_VECTOR, (data: sensor.RotationVectorResponse) => {
        this.onRotationVectorChanged(data);
      }, { interval: SENSOR_UPDATE_INTERVAL });

      console.info(TAG, 'Rotation vector sensor registered successfully');
    } catch (error) {
      console.error(TAG, `Failed to register rotation vector sensor: ${error.message}`);
      // 如果都不可用，发送错误
      if (this.eventSink != null) {
        this.eventSink.error("SENSOR_UNAVAILABLE", "No compass sensor available on this device", null);
      }
    }
  }

  /**
   * 注销传感器监听
   */
  private unregisterSensor(): void {
    try {
      console.info(TAG, 'Unregistering sensors');
      sensor.off(sensor.SensorId.ORIENTATION);
      sensor.off(sensor.SensorId.ROTATION_VECTOR);
      console.info(TAG, 'Sensors unregistered successfully');
    } catch (error) {
      console.error(TAG, `Failed to unregister sensors: ${error.message}`);
    }
  }

  /**
   * 处理方向传感器数据
   */
  private onSensorChanged(data: sensor.OrientationResponse): void {
    if (this.eventSink == null) {
      return;
    }

    // OrientationResponse 包含:
    // - alpha: 绕Z轴的旋转角度（0-360度），即指南针方向
    // - beta: 绕X轴的旋转角度（-180到180度）
    // - gamma: 绕Y轴的旋转角度（-90到90度）

    let heading = data.alpha;

    // 确保角度在 0-360 范围内
    if (heading < 0) {
      heading += 360;
    }

    // 平滑处理，避免抖动
    heading = this.smoothHeading(heading);

    // 返回数据格式：[heading, cameraHeading, accuracy]
    // heading: 当前方向角度（0-360，0为北）
    // cameraHeading: 相机模式下的方向（与heading相同）
    // accuracy: 精度（鸿蒙传感器精度，设为 15 表示高精度）
    // 确保所有值都是浮点数类型，避免 Dart 端类型转换错误
    const result = [Number(heading), Number(heading), 15.0];

    this.eventSink.success(result);
    this.lastHeading = heading;
  }

  /**
   * 处理旋转矢量传感器数据（备用方案）
   */
  private onRotationVectorChanged(data: sensor.RotationVectorResponse): void {
    if (this.eventSink == null) {
      return;
    }

    // RotationVectorResponse 包含四元数：x, y, z, w
    // 需要转换为欧拉角来获取方位角

    const x = data.x;
    const y = data.y;
    const z = data.z;
    const w = data.w;

    // 计算方位角（azimuth）
    const azimuth = Math.atan2(
      2.0 * (w * z + x * y),
      1.0 - 2.0 * (y * y + z * z)
    );

    // 转换为度数
    let heading = azimuth * 180.0 / Math.PI;

    // 确保角度在 0-360 范围内
    if (heading < 0) {
      heading += 360;
    }

    // 平滑处理
    heading = this.smoothHeading(heading);

    // 确保所有值都是浮点数类型，避免 Dart 端类型转换错误
    const result = [Number(heading), Number(heading), 15.0];
    this.eventSink.success(result);
    this.lastHeading = heading;
  }

  /**
   * 平滑处理角度值，避免抖动
   * 使用低通滤波器
   */
  private smoothHeading(newHeading: number): number {
    const ALPHA = 0.45;

    // 处理 0/360 度边界情况
    let diff = newHeading - this.lastHeading;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    let smoothed = this.lastHeading + ALPHA * diff;

    // 确保在 0-360 范围内
    if (smoothed < 0) {
      smoothed += 360;
    } else if (smoothed >= 360) {
      smoothed -= 360;
    }

    return smoothed;
  }

  /**
   * 获取插件唯一标识符
   */
  getUniqueClassName(): string {
    return "FlutterCompassPlugin";
  }
}
