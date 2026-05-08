#
# Nexora SDK Podspec
#
Pod::Spec.new do |s|
  s.name             = 'nexora_sdk'
  s.version          = '3.1.0'
  s.summary          = 'High-performance Flutter Hardware SDK with AI Intelligence & Storage.'
  s.description      = <<-DESC
A premium hardware engine for Flutter supporting Camera (Vision AI), Bluetooth LE, FFT Audio, Biometrics, Geofencing, and Device Storage.
                       DESC
  s.homepage         = 'https://github.com/sahil8822/nexora_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sahil' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Frameworks used by native modules
  s.frameworks = 'AVFoundation', 'CoreBluetooth', 'CoreLocation', 'CoreMotion', 'LocalAuthentication', 'AudioToolbox', 'Vision', 'Accelerate'

  # Required for App Store Privacy Compliance
  s.resource_bundles = {'nexora_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
