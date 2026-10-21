// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import Foundation
@testable import OmniWM
import XCTest

final class AppCLIManagerTests: XCTestCase {
    func testInstallCLIIgnoresPathsThatOnlyShareHomePrefix() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("OmniWMCLIInstall-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let homeDirectory = root.appendingPathComponent("home", isDirectory: true)
        let siblingBinDirectory = root.appendingPathComponent("home-other/bin", isDirectory: true)
        let userBinDirectory = homeDirectory.appendingPathComponent("bin", isDirectory: true)
        let bundleURL = root.appendingPathComponent("Greedless Manager.app", isDirectory: true)
        let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/greedlessctl")
        for directory in [
            homeDirectory,
            siblingBinDirectory,
            userBinDirectory,
            executableURL.deletingLastPathComponent()
        ] {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try "#!/bin/sh\nexit 0\n".write(to: executableURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executableURL.path)

        let fallbackDirectory = homeDirectory.appendingPathComponent(".local/bin", isDirectory: true)
        for (pathDirectories, expectedDirectory, directoryOnPath) in [
            ([siblingBinDirectory], fallbackDirectory, false),
            ([siblingBinDirectory, userBinDirectory], userBinDirectory, true)
        ] {
            let manager = AppCLIManager(
                environmentProvider: {
                    ["PATH": pathDirectories.map { $0.standardizedFileURL.path }.joined(separator: ":")]
                },
                bundleURLProvider: { bundleURL },
                homeDirectoryURLProvider: { homeDirectory.standardizedFileURL },
                homebrewLinkURLsProvider: { [] }
            )
            let expectedLinkURL = expectedDirectory.standardizedFileURL.appendingPathComponent("greedlessctl")

            XCTAssertEqual(
                try manager.installCLIToPATH(),
                .installed(linkURL: expectedLinkURL, directoryOnPath: directoryOnPath)
            )
            XCTAssertFalse(fileManager
                .fileExists(atPath: siblingBinDirectory.appendingPathComponent("greedlessctl").path))
        }
    }

    func testInstallAndRemoveLeaveUpstreamCLIUntouched() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("GreedlessCLIInstall-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        let homeDirectory = root.appendingPathComponent("home", isDirectory: true)
        let binDirectory = homeDirectory.appendingPathComponent("bin", isDirectory: true)
        let bundleURL = root.appendingPathComponent("Greedless Manager.app", isDirectory: true)
        let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/greedlessctl")
        try fileManager.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "#!/bin/sh\nexit 0\n".write(to: executableURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executableURL.path)
        let upstreamCLIURL = binDirectory.appendingPathComponent("omniwmctl")
        let upstreamContents = Data("upstream executable".utf8)
        try upstreamContents.write(to: upstreamCLIURL)

        let manager = AppCLIManager(
            environmentProvider: { ["PATH": binDirectory.path] },
            bundleURLProvider: { bundleURL },
            homeDirectoryURLProvider: { homeDirectory },
            homebrewLinkURLsProvider: { [] }
        )
        let expectedLinkURL = binDirectory.standardizedFileURL.appendingPathComponent("greedlessctl")
        XCTAssertEqual(try manager.installCLIToPATH(), .installed(linkURL: expectedLinkURL, directoryOnPath: true))
        XCTAssertEqual(
            try fileManager.destinationOfSymbolicLink(atPath: expectedLinkURL.path),
            executableURL.path
        )
        XCTAssertEqual(try manager.removeInstalledCLI(), .removed(linkURL: expectedLinkURL))
        XCTAssertFalse(fileManager.fileExists(atPath: expectedLinkURL.path))
        XCTAssertEqual(try Data(contentsOf: upstreamCLIURL), upstreamContents)
    }
}
