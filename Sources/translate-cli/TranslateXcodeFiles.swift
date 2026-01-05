  //
  //  TranslateXcodeFiles.swift
  //  translate-cli
  //
  //  Created by Armin Briegel on 2026-01-03.
  //

import Foundation
import ArgumentParser
import Translation

struct TranslateXcodeFiles: AsyncParsableCommand {
  enum State: String, ExpressibleByArgument {
    case translated
    case needsReview = "needs_review"
  }
  
  static let configuration = CommandConfiguration(
    commandName: "xcode",
    abstract: "Translate fields in xcstrings files.",
    discussion: """
      Use this to take a xcstrings file and create a new file with the translations, \
      provided by the translation service, filled in.
      """,
    aliases: ["xc"]
  )
  
  // MARK: arguments
  
  @ParentCommand var parent: Translate
  
  @Argument(help: "path to source file")
  var sourcePath: String
  
  @Argument(help: "path to translated output file")
  var outputPath: String?
  
  @Option(help: "Target language code.")
  var to: [Locale.Language]
  
  @Option(help: "state that is set on translated strings")
  var state: State = .needsReview
  
  @Flag(name: .long, help: "Overwrite existing translations.")
  var overwriteTranslations: Bool = false
  
  @Flag(name: .long, help: "dry run, don't write anything")
  var dryRun: Bool = false
  
  // MARK: functions
  
  func loadXCStrings(_ url: URL) -> [String: Any]? {
    /// Read the file
    if let data = try? Data(contentsOf: url) {
      return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    return nil
  }
  
  func translateXCString(_ stringsDict: [String:Any]) async throws -> [String:Any] {
    // get source language
    let sourceLanguageCode = (stringsDict["stringsFileLanguageCode"] as? String) ?? "en"
    print("Source language: \(sourceLanguageCode)")
    
    let sourceLanguage = Locale.Language(identifier: sourceLanguageCode)
    
    print("Target languages: \(to.map(\.minimalIdentifier).joined(separator: ", "))")
    
    guard let strings = stringsDict["strings"] as? [String: Any] else {
      try exit("no translatable strings in xcstrings file at \(sourcePath)", code: EX_DATAERR)
    }
    
    var translatedStrings: [String: Any] = [:]
    
    // loop through strings
    for (key, value) in strings {
      guard let value = value as? [String:Any] else {
        print("⚠️ found non-dictionary value for '\(key)', skipping")
        continue
      }
      
      // respect 'shouldTranslate' key, but still add
      let shouldTranslate = (value["shouldTranslate"] as? Bool) ?? true
      if !shouldTranslate {
        translatedStrings[key] = value
        print("ℹ️ 'shouldTranslate' is false for '\(key)', not translating")
        continue
      }
      
      let engine = TranslateEngine()
      var translatedValue = value
      var localizations = value["localizations"] as? [String:Any] ?? [:]
      // loop through targetTranslations
      for targetLanguage in to {
        let targetLanguageCode = targetLanguage.minimalIdentifier
        // don't translate/replace existing translations
        
        let localization = localizations[targetLanguageCode] as? [String:Any]
        
        if localization != nil && !overwriteTranslations {
          print("ℹ️ '\(key)' already translated to \(targetLanguageCode), skipping")
          continue
        }
        
        // add translations
        do {
          let translated = try await engine.translate(key, from: sourceLanguage, to: targetLanguage)
          print("✅ translated '\(key)' to \(targetLanguageCode): \(translated)")
          let translatedLocalization = [
            "stringUnit": [
              "state": state.rawValue,
              "value": translated
            ]
          ]
          localizations[targetLanguageCode] = translatedLocalization
          
          
        } catch TranslationError.notInstalled {
          print("❌ Translation language for \(targetLanguageCode) is not downloaded, skipping translation for '\(key)'")
          continue
        } catch {
          print("❌ Error: \(error)")
        }
        
      }
      translatedValue["localizations"] = localizations
      translatedStrings[key] = translatedValue
    }
    
    var translatedDict = stringsDict
    translatedDict["strings"] = translatedStrings
    return translatedDict
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
    print(String(data: json, encoding: .utf8) ?? "No data")
    // write to output file
    
    
  }
}
