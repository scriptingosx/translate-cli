//
//  TestEngine.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-06.
//

import Testing
import Foundation
import ArgumentParser

@testable import translate

@Suite("Engine Tests")
struct EngineTests {
  
  @Test("detectLanguage")
  func testDetectLanguage() {
    let engine = Engine()
    
    // Known French phrase should detect as fr
    let fr = engine.detectLanguage("bonjour le monde")
    #expect(fr?.languageCode == "fr")
    
    let empty = engine.detectLanguage("")
    #expect(empty == nil)
  }
  
  @Test("translate")
  func testTranslate() async throws {
    let engine = Engine()
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
