//
//  TestTranslateXCStrings.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-06.
//

import Testing
import Foundation
import ArgumentParser

@testable import translate
@Suite("TranslateXCStrings Tests")
struct TranslateXCStringsTests {
  
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
  
  var testXcodeFiles: TranslateXCStrings {
    var files = TranslateXCStrings()
    files.to = [Locale(identifier: "fr")]
    files.sourcePath = "placeholder"
    files.state = .needsReview
    files.replaceTranslations = false
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
    
    let loader = TranslateXCStrings()
    let loaded = loader.loadXCStrings(tmpURL)
    #expect(loaded != nil && (loaded?["sourceLanguage"] as? String) == "en")
  }
  
  @Test("translateStrings adds translations and respects shouldTranslate")
  func testTranslateStrings() async throws {
    var files = testXcodeFiles
    files.to = [Locale(identifier: "fr")]
    files.sourcePath = "placeholder"
    files.state = .needsReview
    files.replaceTranslations = false
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

