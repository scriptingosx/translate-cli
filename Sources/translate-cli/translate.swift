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
    discussion: """
      This command line tool uses the Translation service to translate text passed as arguments
      from one language to another using Apple's Translation framework.
      """,
    version: "0.1"
  )

  @Argument(help: "The text to translate. When no text is given, text will be read from standard input.")
  var arguments: [String] = []

  @Option(name: .long, help: "Target language code (e.g., 'en', 'fr', 'de', 'ja'). Default is current language.")
  var to: String?

  @Option(name: .long, help: "Source language code. If omitted, auto-detect.")
  var from: String?

  @Flag(help: "detect the language of the text and print the code")
  var detect: Bool = false

  /// returns the `arguments` array as a single string joined with spaces. Throws when the `arguments` array is empty.
  func joinedArguments() throws -> String {
    guard !arguments.isEmpty else {
      print("no text to translate")
      throw ExitCode(2)
    }
    return arguments.joined(separator: " ")
  }

  /// returns either the Language from the `--to` option or the current system language
  var targetLanguage: Locale.Language {
    if let to {
      return Locale.Language(identifier: to)
    } else {
      return Locale.current.language
    }
  }

  /// returns either the language from the `--from` option or the dominant language from the `text`
  func sourceLanguage(_ text: String) -> Locale.Language {
    if let from {
      return Locale.Language(identifier: from)
    } else {
      return detectLanguage(text) ?? Locale.current.language
    }
  }

  /// determines the dominant language of the `text`
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

  func run() async throws {
    let text = arguments.isEmpty ? readFromStdin() : try joinedArguments()

    let sourceLanguage = sourceLanguage(text)

    if detect {
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

