//
//  String+HTML.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 6.01.25.
//

import UIKit

extension String {
    
    public func htmlAttributedString(with attributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString? {
        guard let data = self.data(using: .utf16),
              let html = try? NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        else {
            return nil
        }
        html.addAttributes(attributes, range: NSRange(html.string.startIndex..., in: html.string))
        html.deleteCharacters(in: NSRange(location: html.length - 1, length: 1))
        return html
    }
}
