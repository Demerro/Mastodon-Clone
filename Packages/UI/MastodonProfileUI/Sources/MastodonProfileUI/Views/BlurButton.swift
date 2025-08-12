//
//  BlurButton.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 10.05.25.
//

import UIKit

final class BlurButton: UIControl {
    
    let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        $0.isUserInteractionEnabled = false
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial)))
    
    let imageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
        return $0
    }(UIImageView(frame: .zero))
    
    private var layoutSubviewsVisitedOnce = false
    
    override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 1.0, frequencyResponse: newValue ? 0.2 : 0.5))
            animator.addAnimations {
                self.transform = newValue ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
            }
            animator.startAnimation()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(visualEffectView)
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor).priority(.defaultHigh),
            
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 5.0),
            imageView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 5.0),
            visualEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5.0),
            visualEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5.0),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !layoutSubviewsVisitedOnce else { return }
        layoutSubviewsVisitedOnce = true
        visualEffectView.layoutIfNeeded()
        visualEffectView.layer.cornerRadius = visualEffectView.bounds.width / 4.0
    }
}
