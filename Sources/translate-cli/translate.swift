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
  var arguments: [String]

  @Option(name: .long, help: "Target language code (e.g., 'es', 'fr', 'de', 'ja'). Default is current language.")
  var to: String?

  @Option(name: .long, help: "Source language code. If omitted, auto-detect.")
  var from: String?

  @Flag(help: "detect the language of the text and print the code")
  var detect: Bool = false

  var text: String {
    arguments.joined(separator: " ")
  }

  var targetLanguage: Locale.Language {
    if let to {
      return Locale.Language(identifier: to)
    } else {
      return Locale.current.language
    }
  }

  func detectLanguage(_ text: String) -> Locale.Language {
    if let from {
      return Locale.Language(identifier: from)
    } else {
      if let dominantLanguage = NLLanguageRecognizer.dominantLanguage(for: text) {
        return Locale.Language(identifier: dominantLanguage.rawValue)
      } else {
        return Locale.current.language
      }
    }
  }

  func run() async throws {
    guard !arguments.isEmpty else {
      print("no text to translate")
      throw ExitCode(2)
    }

    let sourceLanguage = detectLanguage(text)

    guard !detect else {
      throw CleanExit.message("\(sourceLanguage.languageCode ?? "unknown")")
    }

    let targetLanguage = targetLanguage

    guard sourceLanguage.languageCode != targetLanguage.languageCode else {
      print("source and target language seem to be the same, use --to and --from options!")
      throw ExitCode(3)
    }

    let session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)

    let result = try await session.translate(text)

    print(result.targetText)
  }
}
