//
//  ComposeView.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import UIKit
import UIKitFoundation

final class ComposeView: View {
    
    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        return $0
    }(UIStackView(frame: .zero))
    
    let textView: UITextView = {
        return $0
    }(UITextView(frame: .zero))
}
