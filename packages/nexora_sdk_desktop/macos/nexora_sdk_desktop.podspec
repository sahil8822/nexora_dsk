Pod::Spec.new do |s|
  s.name             = 'nexora_sdk_desktop'
  s.version          = '3.4.0'
  s.summary          = 'macOS implementation of the Nexora SDK.'
  s.description      = <<-DESC
The macOS native bindings for Nexora SDK, including AVFoundation, CoreBluetooth, and LocalAuthentication.
                       DESC
  s.homepage         = 'https://github.com/sahil8822/my_hardware_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Appic Softwares' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
