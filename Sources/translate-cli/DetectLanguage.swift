//
//  DetectLanguage.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-06.
//

import Foundation
import ArgumentParser

struct DetectLanguage: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "detect",
    abstract: "Detect dominant language in a text.",
    discussion: "uses the Natural Language Classifier to detect the dominant language of the given text.",
  )
  
  @Argument(help: "The text. When no text is given, text will be read from standard input.")
  var arguments: [String] = []
  
  func run() async throws {
    let engine = Engine()
    let text = engine.text(arguments: arguments)
    let result = engine.detectLanguage(text)
    print(result?.minimalIdentifier ?? "??")
  }
}
