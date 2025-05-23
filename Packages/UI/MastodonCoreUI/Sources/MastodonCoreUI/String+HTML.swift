//
//  String+HTML.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 4.05.25.
//

import Foundation

extension String {
    
    public func parseHTML(withAttributes attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString? {
        guard let attributedString = try? NSMutableAttributedString(data: self.data(using: .utf8)!, options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ], documentAttributes: nil) else {
            return nil
        }
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
}
