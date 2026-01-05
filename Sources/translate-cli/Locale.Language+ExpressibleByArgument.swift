//
//  Locale.Language+ExpressibleByArgument.swift
//  translate-cli
//
//  Created by Armin Briegel on 2026-01-04.
//

import Foundation
import ArgumentParser

extension Locale.Language: @retroactive ExpressibleByArgument {
  public init?(argument: String) {
    self = Locale.Language(identifier: argument)
  }

  public var defaultValueDescription: String {
    "Language code, e.g. 'en', 'fr', 'de', 'ja', etc.)."
  }
  
  public var localizedName: String? {
    if let identifier = self.languageCode?.identifier {
      return Locale.current.localizedString(forLanguageCode: identifier)
    } else {
      return nil
    }
  }
}
