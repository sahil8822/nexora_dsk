import Flutter
import UIKit

/**
 * Main iOS Plugin Entry Point.
 * Central coordinator for hardware access, permission requests, and event streams.
 */
public class MyHardwarePlugin: NSObject, FlutterPlugin {
  private let camera = HardwareCameraManager()
  private let bluetooth = HardwareBluetoothManager()
  private let location = HardwareLocationManager()
  private var streamHandler: HardwareStreamHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MyHardwarePlugin()
    
    // Method Channel
    let channel = FlutterMethodChannel(name: "my_hardware_plugin/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Event Channel
    let eventChannel = FlutterEventChannel(name: "my_hardware_plugin/events", binaryMessenger: registrar.messenger())
    let streamHandler = HardwareStreamHandler(camera: instance.camera, bluetooth: instance.bluetooth, location: instance.location)
    eventChannel.setStreamHandler(streamHandler)
    instance.streamHandler = streamHandler
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // Camera
    case "startCamera":
      camera.start()
      result(true)
    case "stopCamera":
      camera.stop()
      result(true)
      
    // Bluetooth
    case "startBluetoothScan":
      bluetooth.startScan()
      result(true)
    case "stopBluetoothScan":
      bluetooth.stopScan()
      result(true)
      
    // GPS
    case "startLocation":
      location.startUpdates()
      result(true)
    case "stopLocation":
      location.stopUpdates()
      result(true)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    camera.stop()
    bluetooth.stopScan()
    location.stopUpdates()
  }
}
