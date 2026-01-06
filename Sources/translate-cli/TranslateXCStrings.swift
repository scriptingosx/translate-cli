  //
  //  TranslateXCStringsFiles.swift
  //  translate-cli
  //
  //  Created by Armin Briegel on 2026-01-03.
  //

import Foundation
import ArgumentParser
import Translation

struct TranslateXCStrings: AsyncParsableCommand {
  enum State: String, ExpressibleByArgument {
    case translated
    case needsReview = "needs_review"
  }
  
  static let configuration = CommandConfiguration(
    commandName: "xcstrings",
    abstract: "Translate fields in xcstrings files.",
    discussion: """
      Use this to take a xcstrings file and create a new file with the translations, \
      provided by the translation service, filled in.
      """,
    aliases: ["xcs"]
  )
  
  // MARK: arguments
  
  @ParentCommand var parent: Translate
  
  @Argument(help: "Path to source file.")
  var sourcePath: String
  
  @Argument(help: "Path to translated output file. When omitted, json is written to stdout.")
  var outputPath: String?
  
  @Option(help: "Target language code.")
  var to: [Locale]
  
  @Option(help: "Set to 'translated' to mark translated strings as such.")
  var state: State = .needsReview
  
  @Flag(name: .long, help: "Replace existing translations.")
  var replaceTranslations: Bool = false
  
  @Flag(name: .long, help: ArgumentHelp("dry run, don't write anything", visibility: .hidden))
  var dryRun: Bool = false
  
  // MARK: functions
  
  func loadXCStrings(_ url: URL) -> [String: Any]? {
    /// Read the file
    if let data = try? Data(contentsOf: url) {
      return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    return nil
  }
  
  func translateStrings(
    _ strings: [String: Any],
    sourceLanguage: Locale.Language
  ) async throws -> [String: Any] {
    var translatedStrings: [String: Any] = [:]
    
    // loop through strings
    for (key, value) in strings {
      errorPrint("\n")
      
      guard let value = value as? [String:Any] else {
        errorPrint("⚠️  found non-dictionary value for '\(key)', skipping")
        continue
      }
      
      // respect 'shouldTranslate' key, but still add
      let shouldTranslate = (value["shouldTranslate"] as? Bool) ?? true
      if !shouldTranslate {
        translatedStrings[key] = value
        errorPrint("ℹ️  'shouldTranslate' is false for '\(key)', not translating")
        continue
      }
      
      let engine = Engine()
      var translatedValue = value
      var localizations = value["localizations"] as? [String:Any] ?? [:]
      
      // get base language value to translation
      guard let baseLocalization = localizations[sourceLanguage.minimalIdentifier] as? [String:Any],
         let baseStringUnit = baseLocalization["stringUnit"] as? [String:String],
         let baseValue = baseStringUnit["value"],
         !baseValue.isEmpty else {
        errorPrint("⚠️  couldn't get base translation for '\(key)', skipping")
        continue
      }
      errorPrint("ℹ️  '\(key)': \(baseValue)")
      
      // loop through targetTranslations
      for targetLocale in to {        
        // don't translate/replace existing translations
        if let localization = localizations[targetLocale.identifier] as? [String:Any],
           let stringUnit = localization["stringUnit"] as? [String:String],
           let stringValue = stringUnit["value"],
           !stringValue.isEmpty,
           !replaceTranslations {
          errorPrint("ℹ️  \(targetLocale.identifier): translation exists")
          continue
        }
        
        // add translations
        do {
          let translated = try await engine.translate(baseValue, from: sourceLanguage, to: targetLocale.language)
          errorPrint("✅ \(targetLocale.identifier): \(translated)")
          let translatedLocalization = [
            "stringUnit": [
              "state": state.rawValue,
              "value": translated
            ]
          ]
          localizations[targetLocale.identifier] = translatedLocalization
        } catch {
          errorPrint("❌ Error: \(error)")
          continue
        }
        
      }
      translatedValue["localizations"] = localizations
      translatedStrings[key] = translatedValue
    }
    return translatedStrings
  }
  
  func translateXCString(_ stringsDict: [String:Any]) async throws -> [String:Any] {
    // get source language
    let sourceLanguageCode = (stringsDict["sourceLanguage"] as? String) ?? "en"
    
    let sourceLocale = Locale(identifier: sourceLanguageCode)
    let sourceLanguage = sourceLocale.language
    errorPrint("Source language: \(sourceLanguage.minimalIdentifier) (\(sourceLanguageCode))")
    
    errorPrint("Target languages: \(to.compactMap(\.language.minimalIdentifier).joined(separator: ", "))")
    
    guard let strings = stringsDict["strings"] as? [String: Any] else {
      try exit("no translatable strings in xcstrings file at \(sourcePath)", code: EX_DATAERR)
    }
    
    var translatedDict = stringsDict
    translatedDict["strings"] = try await translateStrings(strings, sourceLanguage: sourceLanguage)
    return translatedDict
  }

  func writeToFile(_ data: Data) throws {
    if !dryRun, let outputPath = outputPath {
      let outputURL = URL(filePath: outputPath)
      do {
        try data.write(to: outputURL)
        errorPrint("✅ Successfully wrote translated file to \(outputPath)")
      } catch {
        try exit("❌ Failed to write to \(outputPath): \(error)", code: EX_CANTCREAT)
      }
    } else if dryRun {
      errorPrint("ℹ️  Dry run: not writing output file.")
    } else {
      errorPrint("ℹ️  No output path provided, printing result to stdout.")
      errorPrint("")
      print(String(data: data, encoding: .utf8) ?? "No data")
    }
  }

  // MARK: run()
  
  mutating func run() async throws {
    // check if file exists
    guard FileManager.default.fileExists(atPath: sourcePath) else {
      try exit("Source file not found at \(sourcePath)", code: EX_NOINPUT)
    }
    
    let sourceURL = URL(filePath: sourcePath)
    
    guard sourceURL.pathExtension == "xcstrings",
          let stringsDict = loadXCStrings(sourceURL) else {
      try exit("Failed to read xcstrings file at \(sourcePath)", code: EX_DATAERR)
    }
    
    guard let translatedDict = try? await translateXCString(stringsDict) else {
      try exit("could not translate", code: EX_DATAERR)
    }
    
    let json = try JSONSerialization.data(withJSONObject: translatedDict, options: .prettyPrinted)
    
    errorPrint("\n")
    
    try writeToFile(json)
  }
}
