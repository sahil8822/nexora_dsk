#
# Nexora SDK Podspec
#
Pod::Spec.new do |s|
  s.name             = 'nexora_sdk_ios'
  s.version          = '3.1.2'
  s.summary          = 'High-performance Flutter Hardware SDK with AI Intelligence & Storage.'
  s.description      = <<-DESC
A premium hardware engine for Flutter supporting Camera (Vision AI), Bluetooth LE, FFT Audio, Biometrics, Geofencing, and Device Storage.
                       DESC
  s.homepage         = 'https://github.com/sahil8822/nexora_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sahil' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.swift', '../../../src/*.{h,cpp}'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Read Podfile macros
  camera_enabled = defined?($NexoraEnableCamera) ? $NexoraEnableCamera : true
  bluetooth_enabled = defined?($NexoraEnableBluetooth) ? $NexoraEnableBluetooth : true
  location_enabled = defined?($NexoraEnableLocation) ? $NexoraEnableLocation : true
  audio_enabled = defined?($NexoraEnableAudio) ? $NexoraEnableAudio : true
  biometric_enabled = defined?($NexoraEnableBiometric) ? $NexoraEnableBiometric : true
  nfc_enabled = defined?($NexoraEnableNfc) ? $NexoraEnableNfc : true

  swift_flags = []
  swift_flags << '-DNEXORA_ENABLE_CAMERA' if camera_enabled
  swift_flags << '-DNEXORA_ENABLE_BLUETOOTH' if bluetooth_enabled
  swift_flags << '-DNEXORA_ENABLE_LOCATION' if location_enabled
  swift_flags << '-DNEXORA_ENABLE_AUDIO' if audio_enabled
  swift_flags << '-DNEXORA_ENABLE_BIOMETRIC' if biometric_enabled
  swift_flags << '-DNEXORA_ENABLE_NFC' if nfc_enabled

  excluded_files = []
  excluded_files << 'Classes/HardwareCameraManager.swift' unless camera_enabled
  excluded_files << 'Classes/HardwareBluetoothManager.swift' unless bluetooth_enabled
  excluded_files << 'Classes/HardwareLocationManager.swift' unless location_enabled
  excluded_files << 'Classes/HardwareAudioManager.swift' unless audio_enabled
  excluded_files << 'Classes/HardwareBiometricManager.swift' unless biometric_enabled
  excluded_files << 'Classes/HardwareNfcManager.swift' unless nfc_enabled

  s.exclude_files = excluded_files

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_SWIFT_FLAGS' => swift_flags.join(' ')
  }
  s.swift_version = '5.0'

  # Frameworks used by native modules
  s.frameworks = 'AVFoundation', 'CoreBluetooth', 'CoreLocation', 'CoreMotion', 'LocalAuthentication', 'AudioToolbox', 'Vision', 'Accelerate'

  # Required for App Store Privacy Compliance
  s.resource_bundles = {'nexora_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
