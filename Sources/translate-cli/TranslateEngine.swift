//
//  TranslateEngine.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-05.
//

import Foundation
import ArgumentParser
import Translation

struct TranslateEngine {
  /// returns the translation for `text`, `source` and `target`
  func translate(
    _ text: String,
    from source: Locale.Language,
    to target: Locale.Language
  ) async throws -> String {
    guard source.languageCode != target.languageCode else {
      print("source and target language seem to be the same, use --to and --from options!")
      throw ExitCode(3)
    }
    
    let session = TranslationSession(installedSource: source, target: target)
    
    let result = try await session.translate(text)
    
    return result.targetText
  }

}
