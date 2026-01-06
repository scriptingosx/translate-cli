//
//  TranslateArguments.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-03.
//

import Foundation
import ArgumentParser

struct TranslateArguments: AsyncParsableCommand {

  static let configuration = CommandConfiguration(
    commandName: "translate",
    abstract: "Translate text using Apple Translation.",
    discussion: "Translates text passed as arguments from one language to another.",
  )

  @Argument(help: "The text to translate. When no text is given, text will be read from standard input.")
  var arguments: [String] = []

  @Option(
    name: .long,
    parsing: .singleValue,
    help: "Target language code. Default is current language."
  )
  var to: [Locale] = []

  @Option(name: .long, help: "Source language code. If omitted, auto-detect.")
  var from: Locale?

  /// returns the `arguments` array as a single string joined with spaces. Throws when the `arguments` array is empty.
  func joined(arguments: [String]) throws -> String {
    guard !arguments.isEmpty else {
      errorPrint("no text to translate")
      throw ExitCode(2)
    }
    return arguments.joined(separator: " ")
  }

  /// returns either the Language from the `--to` option or the current system language
  lazy var targetLanguages: [Locale.Language] = {
    if to.count > 0 {
      return to.compactMap(\.language)
    } else {
      return [ Locale.current.language ]
    }
  }()

  /// returns either the language from the `--from` option or the dominant language from the `text`
  func sourceLanguage(_ text: String) -> Locale.Language {
    let engine = Engine()
    return from?.language ?? engine.detectLanguage(text) ?? Locale.current.language
  }

  /// reads a string of text from standard in
  func readFromStdin () -> String {
    var lines: [String] = []

    while let line = readLine() {
      lines.append(line)
    }

    return lines.joined(separator: "\n")
  }

  mutating func run() async throws {
    let engine = Engine()

    let text = engine.text(arguments: arguments)
    let sourceLanguage = sourceLanguage(text)

    if targetLanguages.count == 1,
       let targetLanguage = targetLanguages.first {
      
      let translation = try await engine.translate(text, from: sourceLanguage, to: targetLanguage)
      print(translation)
    } else {
      for targetLanguage in targetLanguages {
        let translation = try await engine.translate(text, from: sourceLanguage, to: targetLanguage)
        print("\(targetLanguage.languageCode, default: "??"): \(translation)")
      }
    }
  }

}
