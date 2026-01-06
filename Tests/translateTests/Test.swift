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
    let translate = TranslateArguments()
    
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
    var cmdWithTo = TranslateArguments()
    cmdWithTo.to = [Locale(identifier: "fr")]
    let targetWithTo = cmdWithTo.targetLanguages
    #expect(targetWithTo.first?.languageCode == "fr")
    
    // Case 2: without --to option, falls back to current
    var cmdNoTo = TranslateArguments()
    cmdNoTo.to = []
    let targetNoTo = cmdNoTo.targetLanguages
    #expect(targetNoTo.first?.languageCode == Locale.current.language.languageCode)
  }
  
  @Test("sourceLanguage")
  func testSourceLanguage() {
    // Case 1: with --from option
    var cmdWithFrom = TranslateArguments()
    cmdWithFrom.from = Locale(identifier: "en")
    let srcWithFrom = cmdWithFrom.sourceLanguage("bonjour")
    #expect(srcWithFrom.languageCode == "en")
    
    // Case 2: without --from option, should detect dominant language from text
    var cmdDetect = TranslateArguments()
    cmdDetect.from = nil
    let detected = cmdDetect.sourceLanguage("bonjour")
    #expect(detected.languageCode == "fr")
  }
  
  @Test("detectLanguage")
  func testDetectLanguage() {
    var cmd = TranslateArguments()
    // Clear options to ensure pure detection
    cmd.from = nil
    cmd.to = []
    
    // Known French phrase should detect as fr
    let fr = cmd.detectLanguage("bonjour le monde")
    #expect(fr?.languageCode == "fr")
    
    let empty = cmd.detectLanguage("")
    #expect(empty == nil)
  }
}

@Suite("TranslateEngine Tests")
struct TranslateEngineTests {
  @Test("translate")
  func testTranslate() async throws {
    let engine = TranslateEngine()
    let en = Locale.Language(languageCode: "en")
    let fr = Locale.Language(languageCode: "fr")
    
    await #expect(throws: ExitCode.self) {
      try await engine.translate("Hello", from: en, to: en)
    }
    
    let frToEn = try await engine.translate("Bonjour", from: fr, to: en)
    #expect(frToEn == "Hello")
    
    let enToFr = try await engine.translate("Hello", from: en, to: fr)
    #expect(enToFr == "Bonjour")
  }
}



@Suite("TranslateXcodeFiles Tests")
struct TranslateXcodeFilesTests {
  
  // simple a .xcstrings file structure
  var testXCStringsDict: [String: Any] {
    [
      "sourceLanguage": "en",
      "strings": [
        "GREETING": [
          "localizations": [
            "en": [
              "stringUnit": ["value": "Hello"]
            ]
          ]
        ],
        "SKIP": [
          "shouldTranslate": false,
          "localizations": [
            "en": ["stringUnit": ["value": "Skip!"]]
          ]
        ]
      ]
    ]
  }
  
  var testXcodeFiles: TranslateXcodeFiles {
    var files = TranslateXcodeFiles()
    files.to = [Locale(identifier: "fr")]
    files.sourcePath = "placeholder"
    files.state = .needsReview
    files.overwriteTranslations = false
    files.dryRun = false
    return files
  }
  
  @Test("loadXCStrings loads valid data")
  func testLoadXCStrings() async throws {
    // Write fake data to temp file and load
    let dict = testXCStringsDict
    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
    let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.xcstrings")
    try data.write(to: tmpURL)
    defer { try? FileManager.default.removeItem(at: tmpURL) }
    
    let loader = TranslateXcodeFiles()
    let loaded = loader.loadXCStrings(tmpURL)
    #expect(loaded != nil && (loaded?["sourceLanguage"] as? String) == "en")
  }
  
  @Test("translateStrings adds translations and respects shouldTranslate")
  func testTranslateStrings() async throws {
    var files = testXcodeFiles
    files.to = [Locale(identifier: "fr")]
    files.sourcePath = "placeholder"
    files.state = .needsReview
    files.overwriteTranslations = false
    files.dryRun = false
    // Replace engine within function
    let sourceLang = Locale(identifier: "en").language
    let input = testXCStringsDict["strings"] as! [String: Any]
    // Patch engine
    let result = try await files.translateStrings(input, sourceLanguage: sourceLang)
    #expect((result["GREETING"] as? [String: Any]) != nil)
    let greetingLocalizations = (result["GREETING"] as! [String: Any])["localizations"] as! [String: Any]
    #expect(greetingLocalizations["fr"] != nil)

    let greetingStringUnit = (greetingLocalizations["fr"] as! [String: Any])
    let greetingValue = (greetingStringUnit["stringUnit"] as! [String: String])["value"]
    #expect(greetingValue == "Bonjour")
    
    // shouldTranslate false should keep entry untouched
    let skip = result["SKIP"] as! [String: Any]
    let skipLocalizations = skip["localizations"] as! [String: Any]
    #expect(skipLocalizations["fr"] == nil)
  }
  
  @Test("translateXCString handles real xcstrings structure")
  func testTranslateXCString() async throws {
    let cmd = testXcodeFiles
    let dict = testXCStringsDict
    let out = try await cmd.translateXCString(dict)
    #expect((out["strings"] as? [String: Any]) != nil)
    let strings = out["strings"] as! [String: Any]
    #expect(strings["GREETING"] != nil)
  }
}

