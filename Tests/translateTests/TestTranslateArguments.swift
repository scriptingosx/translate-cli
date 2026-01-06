//
//  TestTranslateArguments.swift
//  translate-cli
//
//  Created by Armin Briegel on 2025-12-27.
//

import Testing
import Foundation
import ArgumentParser

@testable import translate

@Suite("TranslateArguments Tests")
struct TestTranslateArguments {
  
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
}

