//
//  File.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-03.
//

import Foundation
import ArgumentParser

struct TranslateXcodeFiles: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "xcode",
    abstract: "Translate fields in xcstrings or xcloc files.",
    discussion: """
      Use this to take a xcstrings or xcloc file and create a new file with the translations,
      provided by the translation service, filled in.
      """,
    aliases: ["xc", "xcstrings", "xcloc"]
  )

  @ParentCommand var translate: Translate

  mutating func run() async throws {
    
  }
}
