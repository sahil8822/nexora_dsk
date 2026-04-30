import Flutter
import UIKit
import AVFoundation

public class NexoraSdk: NSObject, FlutterPlugin {
  private let camera = HardwareCameraManager()
  private let audio = HardwareAudioManager()
  private let sensors = HardwareSensorManager()
  private let bluetooth = HardwareBluetoothManager()
  private let location = HardwareLocationManager()
  private let biometrics = HardwareBiometricManager()
  private let feedback = HardwareFeedbackManager()
  private let health = HardwareHealthManager()
  
  private var registrar: FlutterPluginRegistrar?
  private var textureId: Int64 = -1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NexoraSdk()
    instance.registrar = registrar
    
    let channel = FlutterMethodChannel(name: "nexora_sdk/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(name: "nexora_sdk/events", binaryMessenger: registrar.messenger())
    let streamHandler = HardwareStreamHandler(camera: instance.camera, bluetooth: instance.bluetooth, location: instance.location, sensor: instance.sensors, audio: instance.audio)
    eventChannel.setStreamHandler(streamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    
    switch call.method {
    case "startCamera":
      // Optimized: Register Texture for Preview
      textureId = registrar?.textures().register(camera) ?? -1
      camera.start(width: args?["width"] as? Int ?? 640, height: args?["height"] as? Int ?? 480)
      result(textureId)
      
    case "stopCamera":
      camera.stop()
      if textureId != -1 { registrar?.textures().unregisterTexture(textureId) }
      result(true)
      
    case "setVisionMode":
      camera.setVisionMode(face: args?["face"] as? Bool ?? false, barcode: args?["barcode"] as? Bool ?? false)
      result(true)
      
    case "startAudio":
      audio.setFFTEnabled(args?["enableFFT"] as? Bool ?? false)
      result(audio.start())

    // ... Other methods remain consistent ...
    case "authenticate":
      biometrics.authenticate(reason: args?["reason"] as? String ?? "Auth") { result($0) }
    case "vibrate":
      feedback.vibrate(duration: args?["duration"] as? Int ?? 50); result(nil)
    case "hapticFeedback":
      feedback.haptic(type: args?["type"] as? String ?? "impact"); result(nil)
    case "getBatteryInfo": result(health.getBatteryInfo())
    case "startLogging":
      health.startLogging(fileName: args?["fileName"] as? String ?? "log.csv", interval: args?["interval"] as? Double ?? 1000.0)
      result(true)
    case "stopLogging": health.stopLogging(); result(true)
    case "startLocation": location.startUpdates(); result(true)
    case "stopLocation": location.stopUpdates(); result(true)
    case "addGeofence":
      location.addGeofence(id: args?["id"] as? String ?? "", lat: args?["lat"] as? Double ?? 0, lon: args?["lon"] as? Double ?? 0, radius: args?["radius"] as? Double ?? 100)
      result(true)
    case "getPlatformVersion": result("iOS " + UIDevice.current.systemVersion)
    case "requestPermissions": result(true)
    default: result(FlutterMethodNotImplemented)
    }
  }
}
