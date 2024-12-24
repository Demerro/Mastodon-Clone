//
//  Int+RoundedWithAbbreviations.swift
//  SwiftUtilities
//
//  Created by Nikita Prokhorchuk on 6.12.24.
//

import Foundation

extension Int {
    
    public var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000.0
        let million = number / 1000000.0
        return if million >= 1.0 {
            "\(round(million * 10.0) / 10.0)M"
        } else if thousand >= 1.0 {
            "\(round(thousand * 10.0) / 10.0)k"
        } else {
            "\(self)"
        }
    }
}
