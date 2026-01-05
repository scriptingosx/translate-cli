//
//  TranslateArguments.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-03.
//

import Foundation
import ArgumentParser
import NaturalLanguage
import Translation

struct TranslateArguments: AsyncParsableCommand {

  static let configuration = CommandConfiguration(
    commandName: "text",
    abstract: "Translate text using Apple Translation.",
    discussion: """
      Translates text passed as arguments from one language to another.
      """,
  )

  @Argument(help: "The text to translate. When no text is given, text will be read from standard input.")
  var arguments: [String] = []

  @Option(
    name: .long,
    parsing: .singleValue,
    help: "Target language code. Default is current language."
  )
  var to: [Locale.Language] = []

  @Option(name: .long, help: "Source language code. If omitted, auto-detect.")
  var from: Locale.Language?

  @Flag(help: "detect the language of the text and print the code")
  var detect: Bool = false

  /// returns the `arguments` array as a single string joined with spaces. Throws when the `arguments` array is empty.
  func joined(arguments: [String]) throws -> String {
    guard !arguments.isEmpty else {
      print("no text to translate")
      throw ExitCode(2)
    }
    return arguments.joined(separator: " ")
  }

  /// returns either the Language from the `--to` option or the current system language
  var targetLanguages: [Locale.Language] {
    if to.count > 0 {
      return to
    } else {
      return [ Locale.current.language ]
    }
  }

  /// returns either the language from the `--from` option or the dominant language from the `text`
  func sourceLanguage(_ text: String) -> Locale.Language {
    from ?? detectLanguage(text) ?? Locale.current.language
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

  func run() async throws {
    let text = arguments.isEmpty ? readFromStdin() : try joined(arguments: arguments)
    let sourceLanguage = sourceLanguage(text)

    if detect {
      throw CleanExit.message("\(sourceLanguage.languageCode ?? "unknown")")
    }

    if to.count == 1,
       let targetLanguage = targetLanguages.first {
      let translation = try await translate(text, from: sourceLanguage, to: targetLanguage)
      print(translation)
    } else {
      for targetLanguage in targetLanguages {
        let translation = try await translate(text, from: sourceLanguage, to: targetLanguage)
        print("\(targetLanguage.languageCode, default: "??"): \(translation)")
      }
    }
  }

}
