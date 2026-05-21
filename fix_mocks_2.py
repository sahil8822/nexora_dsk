with open('test/mocks/mock_platform.dart', 'r') as f:
    text = f.read()

# Update startCamera
text = text.replace("Future<dynamic> startCamera({int width = 1280, int height = 720}) =>\n      Future.value(true);", "Future<int?> startCamera({int width = 1280, int height = 720}) =>\n      Future.value(1);")
text = text.replace("Future<dynamic> startCameraWithOptions(CameraOptions options) =>\n      Future.value(true);", "Future<int?> startCameraWithOptions(CameraOptions options) =>\n      Future.value(1);")

with open('test/mocks/mock_platform.dart', 'w') as f:
    f.write(text)
