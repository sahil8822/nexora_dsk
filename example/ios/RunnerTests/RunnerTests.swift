import Flutter
import UIKit
import XCTest

@testable import nexora_sdk_ios

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() {
    let plugin = NexoraSdk()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as? String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testUnimplementedMethod() {
    let plugin = NexoraSdk()

    let call = FlutterMethodCall(methodName: "nonExistentMethodXYZ", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result is FlutterMethodNotImplemented.Type || (result as? NSObject) === FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
