// SPDX-License-Identifier: GPL-2.0-only

import Foundation
import OmniWMIPC
import XCTest

final class IPCSocketPathTests: XCTestCase {
    func testDefaultSocketAndSecretUseForkNamespace() {
        let path = IPCSocketPath.resolvedPath(environment: [:])
        let expectedPath = URL.applicationSupportDirectory.path + "/org.greedless.manager/ipc.sock"

        XCTAssertEqual(path, expectedPath)
        XCTAssertEqual(IPCSocketPath.secretPath(forSocketPath: path), expectedPath + ".secret")
    }

    func testForkOverrideSelectsSocketAndMatchingSecret() {
        let path = IPCSocketPath.resolvedPath(environment: ["GREEDLESS_SOCKET": "/tmp/greedless-test.sock"])

        XCTAssertEqual(path, "/tmp/greedless-test.sock")
        XCTAssertEqual(IPCSocketPath.secretPath(forSocketPath: path), "/tmp/greedless-test.sock.secret")
    }

    func testInheritedUpstreamOverrideCannotSelectUpstreamSocket() {
        let path = IPCSocketPath.resolvedPath(environment: ["OMNIWM_SOCKET": "/tmp/upstream.sock"])

        XCTAssertEqual(path, URL.applicationSupportDirectory.path + "/org.greedless.manager/ipc.sock")
    }

    func testForkOverrideWinsWhenBothVariablesArePresent() {
        let path = IPCSocketPath.resolvedPath(environment: [
            "GREEDLESS_SOCKET": "/tmp/greedless-test.sock",
            "OMNIWM_SOCKET": "/tmp/upstream.sock"
        ])

        XCTAssertEqual(path, "/tmp/greedless-test.sock")
    }

    func testEmptyForkOverrideDoesNotFallBackToUpstreamOverride() {
        let path = IPCSocketPath.resolvedPath(environment: [
            "GREEDLESS_SOCKET": "",
            "OMNIWM_SOCKET": "/tmp/upstream.sock"
        ])

        XCTAssertEqual(path, URL.applicationSupportDirectory.path + "/org.greedless.manager/ipc.sock")
    }
}
