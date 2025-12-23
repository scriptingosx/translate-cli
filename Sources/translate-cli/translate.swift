// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Translation
import NaturalLanguage

@main
struct Translate: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "translate",
    abstract: "Translate text to a target language using Apple Translation.",
    version: "0.1"
  )

  @Argument(help: "The text to translate.")
  var text: [String]

  @Option(name: .shortAndLong, help: "Target language code (e.g., 'es', 'fr', 'de', 'ja').")
  var to: String

  @Option(name: .shortAndLong, help: "Source language code (optional). If omitted, auto-detect.")
  var from: String?

  func run() async throws {
    guard !text.isEmpty else {
      throw CleanExit.message("no text to translate")
    }

    let text = text.joined(separator: " ")

    let targetLanguage = Locale.Language(identifier: to)
    let sourceLanguage: Locale.Language

    if let from {
      sourceLanguage = Locale.Language(identifier: from)
    } else {
      if let dominantLanguage = NLLanguageRecognizer.dominantLanguage(for: text) {
        let language = Locale.Language(identifier: dominantLanguage.rawValue)
        sourceLanguage = language
      } else {
        sourceLanguage = Locale.current.language
      }
    }

    let session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)

    let result = try await session.translate(text)

    print(result.targetText)
  }
}
