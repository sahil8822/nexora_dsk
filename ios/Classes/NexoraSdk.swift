import Flutter
import UIKit
import AVFoundation
import CoreLocation
import CoreBluetooth

/**
 * Main iOS Plugin Entry Point.
 * Central coordinator for hardware access, permission requests, and event streams.
 */
public class NexoraSdk: NSObject, FlutterPlugin {
  private let camera = HardwareCameraManager()
  private let bluetooth = HardwareBluetoothManager()
  private let location = HardwareLocationManager()
  private let sensor = HardwareSensorManager()
  private var streamHandler: HardwareStreamHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NexoraSdk()
    
    // Method Channel
    let channel = FlutterMethodChannel(name: "nexora_sdk/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Event Channel
    let eventChannel = FlutterEventChannel(name: "nexora_sdk/events", binaryMessenger: registrar.messenger())
    let streamHandler = HardwareStreamHandler(camera: instance.camera, bluetooth: instance.bluetooth, location: instance.location, sensor: instance.sensor)
    eventChannel.setStreamHandler(streamHandler)
    instance.streamHandler = streamHandler
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // Camera
    case "startCamera":
      let args = call.arguments as? [String: Any]
      let width = args?["width"] as? Int ?? 640
      let height = args?["height"] as? Int ?? 480
      camera.start(width: width, height: height)
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
      
    case "startSensor":
      let args = call.arguments as? [String: Any]
      let freq = args?["frequency"] as? Int ?? 60
      sensor.start(frequencyHz: freq)
      result(true)
    case "stopSensor":
      sensor.stop()
      result(true)
      
    case "requestPermissions":
      requestPermissions(result: result)
      
    case "connectDevice":
      if let args = call.arguments as? [String: Any],
         let deviceId = args["id"] as? String {
        bluetooth.connect(deviceId: deviceId)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Device ID is null", details: nil))
      }

    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    let group = DispatchGroup()
    var cameraGranted = false
    var locationGranted = false
    
    // Camera
    group.enter()
    AVCaptureDevice.requestAccess(for: .video) { granted in
      cameraGranted = granted
      group.leave()
    }
    
    // Location (Just a basic check/request for this example)
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
    locationGranted = CLLocationManager.authorizationStatus() != .denied
    
    group.notify(queue: .main) {
      result(cameraGranted && locationGranted)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    camera.stop()
    bluetooth.stopScan()
    location.stopUpdates()
  }
}
