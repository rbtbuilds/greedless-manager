// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import Foundation
@testable import OmniWMCtl
import OmniWMIPC
import XCTest

final class NuCompletionTests: XCTestCase {
    func testGenerationIsDeterministicAndRendersEveryPlaceholder() {
        let script = CLICompletionGenerator.script(for: .nu)
        XCTAssertFalse(script.contains("#{{"))
        XCTAssertTrue(script.contains("    windowMarkActionNames: ["))
        XCTAssertTrue(script.contains("    windowMarkListFlags: ["))
        XCTAssertEqual(script, CLICompletionGenerator.script(for: .nu))
    }

    func testMissingNushellIsAnExplicitSkip() {
        XCTAssertThrowsError(try NuCompletionTestSupport.nuExecutable(path: "")) { error in
            XCTAssertTrue(error is XCTSkip)
        }
    }

    func testNativeErrorsAreFailures() throws {
        for body in ["def broken [", "exit 7"] {
            do {
                _ = try NuCompletionTestSupport.run(body)
                XCTFail("Expected Nushell to fail: \(body)")
            } catch let skip as XCTSkip {
                throw skip
            } catch {
                XCTAssertFalse(error is XCTSkip)
            }
        }
    }

    func testModuleImportsOnlyTheExternalCommand() throws {
        let output = try NuCompletionTestSupport.run(
            "scope commands | where name =~ 'greedlessctl' | get name | to json"
        )
        XCTAssertEqual(try JSONDecoder().decode([String].self, from: output), ["greedlessctl"])
    }

    func testGeneratedStringLiteralsPreserveSpecialCharacters() throws {
        let value = "A \"quote\", a \\ path,\n\t\r\u{0001} and $'literal' 🙂"
        let output = try NuCompletionTestSupport.run("\(CLICompletionGenerator.nushellString(value)) | encode base64")
        XCTAssertEqual(
            String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
            Data(value.utf8).base64EncodedString()
        )
    }

    func testTopLevelAndActionFamiliesUseCatalogChoices() throws {
        let cases: [(String, [String])] = [
            ("greedlessctl ", CLICompletionCatalog.topLevelCommands),
            ("greedlessctl query ", CLICompletionCatalog.queryNames),
            ("greedlessctl command ", CLICompletionCatalog.commandFirstWords),
            ("greedlessctl rule ", CLICompletionCatalog.ruleActionNames),
            ("greedlessctl capture ", CLICompletionCatalog.captureActionNames),
            ("greedlessctl workspace ", CLICompletionCatalog.workspaceActionNames),
            ("greedlessctl window ", CLICompletionCatalog.windowActionNames),
            ("greedlessctl window mark ", CLICompletionCatalog.windowMarkActionNames),
            ("greedlessctl window mark list ", CLICompletionCatalog.windowMarkListFlags),
            ("greedlessctl completion ", CLIShell.allCases.map(\.rawValue)),
            ("greedlessctl que", ["query"])
        ]
        for (input, expected) in cases {
            try assertCompletions(input, expected)
        }
    }

    func testWindowMarkActionAndListFlagCompletions() throws {
        try assertCompletions("greedlessctl window mark ", CLICompletionCatalog.windowMarkActionNames)
        try assertCompletions("greedlessctl window mark list ", CLICompletionCatalog.windowMarkListFlags)
        try assertCompletions("greedlessctl window mark set saved ", [])
    }

    func testNestedCommandsAndLiteralArguments() throws {
        let cases: [(String, [String])] = [
            ("greedlessctl command focus ", ["left", "right", "up", "down", "previous", "down-or-left", "up-or-right"]),
            ("greedlessctl command scratchpad ", ["assign", "toggle"]),
            ("greedlessctl command scratchpad assign ", (1 ... 10).map(String.init)),
            ("greedlessctl command scratchpad toggle ", (1 ... 10).map(String.init)),
            ("greedlessctl command move-to-monitor ", ["left", "right", "up", "down"]),
            ("greedlessctl command resize ", ["horizontal", "vertical"]),
            ("greedlessctl command resize horizontal ", ["grow", "shrink"]),
            ("greedlessctl capture start ", ["trace", "performance"]),
            ("greedlessctl command resize vertical sh", ["shrink"])
        ]
        for (input, expected) in cases {
            try assertCompletions(input, expected)
        }
        let layout = try XCTUnwrap(IPCAutomationManifest.commandDescriptors.first {
            $0.arguments.first?.kind == .layout
        })
        try assertCompletions(
            "greedlessctl command \(layout.commandWords.joined(separator: " ")) ",
            ["default", "niri", "dwindle"]
        )
    }

    func testQuerySpecificFlagsAndFields() throws {
        try assertCompletions("greedlessctl query windows ", CLICompletionCatalog.queryFlagsByName["windows"] ?? [])
        try assertCompletions("greedlessctl query displays --fields ", IPCAutomationManifest.displayFieldCatalog)
        try assertCompletions("greedlessctl query workspaces --fields display-n", ["display-name"])
        try assertCompletions("greedlessctl query windows --fields id,ti", ["id,title"])
        let remaining = IPCAutomationManifest.windowFieldCatalog.filter { $0 != "id" }.map { "id,\($0)" }
        try assertCompletions("greedlessctl query windows --fields id,", remaining)
    }

    func testRulesAndSubscriptionChoices() throws {
        try assertCompletions("greedlessctl rule add ", CLICompletionCatalog.ruleDefinitionFlags)
        try assertCompletions("greedlessctl rule apply ", CLICompletionCatalog.ruleApplyFlags)
        try assertCompletions("greedlessctl subscribe ", CLICompletionCatalog.subscribeTokens)
        try assertCompletions("greedlessctl watch ", CLICompletionCatalog.watchTokens)
        try assertCompletions("greedlessctl subscribe focus,work", ["focus,workspace-bar"])
        let channels = IPCSubscriptionChannel.allCases.filter { $0 != .focus }.map { "focus,\($0.rawValue)" }
        try assertCompletions("greedlessctl watch focus,", channels)
    }

    func testGlobalAndValueTakingFlagsPreserveArgumentPositions() throws {
        let cases: [(String, [String])] = [
            ("greedlessctl --json command resize horizontal ", ["grow", "shrink"]),
            ("greedlessctl command --format json resize horizontal ", ["grow", "shrink"]),
            ("greedlessctl command resize horizontal --format text ", ["grow", "shrink"]),
            ("greedlessctl query windows --format ", ["json", "ndjson", "table", "tsv", "text"]),
            ("greedlessctl --for", ["--format"]),
            ("greedlessctl query windows --app ", []),
            ("greedlessctl rule add --title-substring ", []),
            ("greedlessctl rule add --layout ", ["auto", "tile", "float"]),
            ("greedlessctl rule add --layout fl", ["float"]),
            ("greedlessctl rule apply --pid ", []),
            ("greedlessctl query windows --app 'Visual Studio Code' --fields ti", ["title"])
        ]
        for (input, expected) in cases {
            try assertCompletions(input, expected)
        }
    }

    func testQuotedWorkspaceTargetsCountAsOneArgument() throws {
        try assertCompletions(
            "greedlessctl workspace move-to-monitor 'Design Space' ",
            ["left", "right", "up", "down", "--force"]
        )
        try assertCompletions(
            "greedlessctl workspace move-to-monitor \"Design Space\" --force --format json ",
            ["left", "right", "up", "down"]
        )
    }

    func testFreeArgumentsAndWatchChildrenDoNotGetOmniWMCompletions() throws {
        for input in [
            "greedlessctl window focus ",
            "greedlessctl workspace focus-name ",
            "greedlessctl command focus-column 3 ",
            "greedlessctl watch focus --exec ",
            "greedlessctl watch focus --exec nu --format ",
            "greedlessctl watch focus --exec nu --json "
        ] {
            try assertCompletions(input, [])
        }
    }

    func testImportedCommandPreservesExternalArguments() throws {
        let cases: [(String, [String])] = [
            (
                "greedlessctl workspace rename 'Design Space' '' --format json",
                ["workspace", "rename", "Design Space", "", "--format", "json"]
            ),
            (
                "greedlessctl watch focus --exec nu -c 'print \"a b\"' --format json",
                ["watch", "focus", "--exec", "nu", "-c", "print \"a b\"", "--format", "json"]
            ),
            (
                "greedlessctl command set-window-primary-span '-10%' --json",
                ["command", "set-window-primary-span", "-10%", "--json"]
            )
        ]
        for (body, expected) in cases {
            let output = try NuCompletionTestSupport.run(body)
            let arguments = String(decoding: output, as: UTF8.self)
                .split(separator: "\0", omittingEmptySubsequences: false).dropLast().map(String.init)
            XCTAssertEqual(arguments, expected, body)
        }
    }

    func testCompletionGenerationDoesNotOpenIPC() async {
        let environment = CLIRuntimeEnvironment(
            openConnection: {
                XCTFail("Completion generation must not open IPC")
                throw POSIXError(.ENOTCONN)
            },
            sleep: { _ in
                XCTFail("Completion generation must not wait for a connection")
            }
        )
        let result = await CLIRuntime.run(arguments: ["greedlessctl", "completion", "nu"], environment: environment)
        XCTAssertEqual(result, CLIExitCode.success.rawValue)
    }

    private func assertCompletions(
        _ input: String,
        _ expected: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let completions = try NuCompletionTestSupport.completions(input)
        XCTAssertEqual(
            Set(completions),
            Set(expected),
            input,
            file: file,
            line: line
        )
    }
}
