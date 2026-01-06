//
//  Engine.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-05.
//

import Foundation
import ArgumentParser
import Translation
import NaturalLanguage

struct Engine {
  
  enum EngineError: Error {
    case noTextToTranslate
  }
  
  /// returns the translation for `text`, `source` and `target`
  func translate(
    _ text: String,
    from source: Locale.Language,
    to target: Locale.Language
  ) async throws -> String {
    // TODO: this should move else where?
    guard source.languageCode != target.languageCode else {
      errorPrint("❌ source and target language seem to be the same, use --to and --from options!")
      throw ExitCode(3)
    }
    
    let session = TranslationSession(installedSource: source, target: target)
    
    do {
      let result = try await session.translate(text)
      return result.targetText
      
    } catch TranslationError.notInstalled {
      errorPrint("""
      ❌ Translation language for \(target.localizedName, default: "??") (\(target.languageCode?.identifier, default: "??")) is not downloaded
      You have to download the Translation resources in 
      
         System Settings > Languge & Region > Translation Languages…
         (button at the bottom of that pane) 

      """)
      throw TranslationError.notInstalled
    }
  }
  
  /// returns the dominant language of the `text`
  func detectLanguage(_ text: String) -> Locale.Language? {
    if let dominantLanguage = NLLanguageRecognizer.dominantLanguage(for: text) {
      return Locale.Language(identifier: dominantLanguage.rawValue)
    } else {
      return nil
    }
  }
  
  /// reads a string of text from standard in
  func readFromStdin () -> String {
    var lines: [String] = []
    
    while let line = readLine() {
      lines.append(line)
    }
    
    return lines.joined(separator: "\n")
  }
  
  /// either returns the joined arguments or text from stdin
  func text(arguments: [String]) -> String {
    arguments.isEmpty ? readFromStdin() : arguments.joined(separator: " ")
  }
}
