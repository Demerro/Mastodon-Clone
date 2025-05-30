//
//  SpoilerTextField.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 26.05.25.
//

import UIKit

final class SpoilerTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        keyboardType = .default
        returnKeyType = .next
        backgroundColor = .systemYellow
        placeholder = "What are we hiding?"
        
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10.0
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let spacing = 10.0
        return CGRect(
            x: bounds.origin.x + spacing,
            y: bounds.origin.y + spacing,
            width: bounds.width - spacing * 2,
            height: bounds.height - spacing * 2
        )
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }
}
