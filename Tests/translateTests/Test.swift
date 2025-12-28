//
//  Test.swift
//  translate-cli
//
//  Created by Armin Briegel on 2025-12-27.
//

import Testing
import Foundation
import ArgumentParser

@testable import translate

@Suite("translate Tests")
struct translateTests {

  @Test("joinedArguments")
  func testJoinedArguments1() {
    let translate = Translate()

    let joined1 = try? translate.joined(arguments: ["Hello"])
    #expect(joined1 == "Hello")

    let joined2 = try? translate.joined(arguments: ["Hello", "World"])
    #expect(joined2 == "Hello World")

    #expect(throws: ExitCode.self) {
      _ = try translate.joined(arguments: [])
    }
  }

  @Test("targetLanguage")
  func testTargetLanguage() {
    // Case 1: with --to option
    var cmdWithTo = Translate()
    cmdWithTo.to = "fr"
    let targetWithTo = cmdWithTo.targetLanguage
    #expect(targetWithTo.languageCode == "fr")

    // Case 2: without --to option, falls back to current
    var cmdNoTo = Translate()
    cmdNoTo.to = nil
    let targetNoTo = cmdNoTo.targetLanguage
    #expect(targetNoTo.languageCode == Locale.current.language.languageCode)
  }

  @Test("sourceLanguage")
  func testSourceLanguage() {
    // Case 1: with --from option
    var cmdWithFrom = Translate()
    cmdWithFrom.from = "en"
    let srcWithFrom = cmdWithFrom.sourceLanguage("bonjour")
    #expect(srcWithFrom.languageCode == "en")

    // Case 2: without --from option, should detect dominant language from text
    var cmdDetect = Translate()
    cmdDetect.from = nil
    let detected = cmdDetect.sourceLanguage("bonjour")
    #expect(detected.languageCode == "fr")
  }

  @Test("detectLanguage")
  func testDetectLanguage() {
    var cmd = Translate()
    // Clear options to ensure pure detection
    cmd.from = nil
    cmd.to = nil

    // Known French phrase should detect as fr
    let fr = cmd.detectLanguage("bonjour le monde")
    #expect(fr?.languageCode == "fr")

    let empty = cmd.detectLanguage("")
    #expect(empty == nil)
  }

  @Test("translate")
  func testTranslate() async throws {
    let cmd = Translate()
    let en = Locale.Language(languageCode: "en")
    let fr = Locale.Language(languageCode: "fr")

    await #expect(throws: ExitCode.self) {
      try await cmd.translate("Hello", from: en, to: en)
    }

    let frToEn = try await cmd.translate("Bonjour", from: fr, to: en)
    #expect(frToEn == "Hello")

    let enToFr = try await cmd.translate("Hello", from: en, to: fr)
    #expect(enToFr == "Bonjour")
  }
}
