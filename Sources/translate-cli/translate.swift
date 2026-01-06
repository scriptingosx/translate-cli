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
    abstract: "Translate using Apple Translation.",
    discussion: """
      This command line tool uses the Translation service to translate text \
      from one language to another using Apple's Translation framework.
      
      Important:
      You have to download the Translation resources in 
      
         System Settings > Languge & Region > Translation Languages…
         (button at the bottom of that pane) 
      
      _before_ using this tool. Otherwise you will get `Error: Unable to Translate` messages. \
      You only need to download the languages you are going to use.    
      """,
    version: "0.3",
    subcommands: [ TranslateArguments.self, DetectLanguage.self, TranslateXCStrings.self],
    defaultSubcommand: TranslateArguments.self
  )

}
