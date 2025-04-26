//
//  Logger+FavouritesCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let favourites = Logger(subsystem: subsystem, category: "Favourites", flag: "Debug")
}
