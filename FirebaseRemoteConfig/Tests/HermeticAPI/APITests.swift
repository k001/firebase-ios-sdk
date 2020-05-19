// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseCore
@testable import FirebaseRemoteConfig

import XCTest

class APITests: XCTestCase {
  var app: FirebaseApp!
  var config: RemoteConfig!

  override class func setUp() {
    FirebaseApp.configure()
  }

  override func setUp() {
    super.setUp()
    app = FirebaseApp.app()
    config = RemoteConfig.remoteConfig(app: app!)
    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    config.configSettings = settings

    FakeFetch.config = ["Key1": "Value1"]

    // Uncomment for verbose debug logging.
    FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.debug)
  }

  override func tearDown() {
    app = nil
    config = nil
    FakeFetch.config = nil
    super.tearDown()
  }

  func testFetchThenActivate() {
    let expectation = self.expectation(description: #function)
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { _, error in
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()
  }

  func testFetchWithExpirationThenActivate() {
    let expectation = self.expectation(description: #function)
    config.fetch(withExpirationDuration: 0) { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { _, error in
        XCTAssertNil(error)
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()
  }

  func testFetchAndActivate() {
    let expectation = self.expectation(description: #function)
    config.fetchAndActivate { status, error in
      if let error = error {
        XCTFail("Fetch and Activate Error \(error)")
      }
      XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
      expectation.fulfill()
    }
    waitForExpectations()
  }

  // Test Deprecated API.
  func testUnchangedActivateWillError() {
    let expectation = self.expectation(description: #function)
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { error in
        if let error = error {
          print("Activate Error \(error)")
        }
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()
    let expectation2 = self.expectation(description: #function + "2")
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { error in
        XCTAssertNotNil(error)
        if let error = error {
          XCTAssertEqual((error as NSError).code, RemoteConfigError.internalError.rawValue)
        }
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation2.fulfill()
      }
    }
    waitForExpectations()
  }

  // Test New API.
  func testUnchangedActivateWillFlag() {
    let expectation = self.expectation(description: #function)
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { (changed, error) in
        XCTAssertFalse(changed)
        if let error = error {
          print("Activate Error \(error)")
        }
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()
    let expectation2 = self.expectation(description: #function + "2")
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { (changed, error) in
        XCTAssertFalse(changed)
        XCTAssertNil(error)
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation2.fulfill()
      }
    }
    waitForExpectations()
  }

  // Test Deprecated API.
  func testChangedActivateWillNotError() {
    let expectation = self.expectation(description: #function)
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { error in
        if let error = error {
          print("Activate Error \(error)")
        }
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()

    // Simulate updating console.
    FakeFetch.config = ["Key1": "Value2"]

    let expectation2 = self.expectation(description: #function + "2")
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { error in
        XCTAssertNil(error)
        XCTAssertEqual(self.config["Key1"].stringValue, "Value2")
        expectation2.fulfill()
      }
    }
    waitForExpectations()
  }

  // Test New API.
  func testChangedActivateWillNotFlag() {
    let expectation = self.expectation(description: #function)
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { (changed, error) in
        XCTAssertNil(error)
        XCTAssert(changed)
        XCTAssertEqual(self.config["Key1"].stringValue, "Value1")
        expectation.fulfill()
      }
    }
    waitForExpectations()

    // Simulate updating console.
    FakeFetch.config = ["Key1": "Value2"]

    let expectation2 = self.expectation(description: #function + "2")
    config.fetch { status, error in
      if let error = error {
        XCTFail("Fetch Error \(error)")
      }
      XCTAssertEqual(status, RemoteConfigFetchStatus.success)
      self.config.activate { (changed, error) in
        XCTAssertNil(error)
        XCTAssert(changed)
        XCTAssertEqual(self.config["Key1"].stringValue, "Value2")
        expectation2.fulfill()
      }
    }
    waitForExpectations()
  }


  private func waitForExpectations() {
    let kFIRStorageIntegrationTestTimeout = 100.0
    waitForExpectations(timeout: kFIRStorageIntegrationTestTimeout,
                        handler: { (error) -> Void in
                          if let error = error {
                            print(error)
                          }
    })
  }
}
