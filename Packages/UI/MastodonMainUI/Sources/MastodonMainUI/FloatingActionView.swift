//
//  FloatingActionView.swift
//  MastodonMainUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import UIKit
import UIKitFoundation

final class FloatingActionView: View {
    
    let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial)))
    
    let button: UIButton = {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.image = UIImage(systemName: "square.and.pencil")!
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        return button
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        RunLoop.current.perform { [button] in
            MainActor.assumeIsolated {
                button.layer.cornerRadius = button.bounds.width / 2.0
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 10.0),
            controlPoint1: CGPoint(x: button.frame.minX - 5.0, y: rect.maxY),
            controlPoint2: CGPoint(x: button.frame.minX - 30.0, y: -10.0)
        )
        let shadowPath = path.cgPath.copy(strokingWithWidth: 1.0, lineCap: .round, lineJoin: .miter, miterLimit: 0.0)
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        layer.mask = shapeLayer
        
        let shadowLayer = CAShapeLayer()
        shadowLayer.shadowPath = shadowPath
        shadowLayer.shadowOffset = .zero
        shadowLayer.shadowOpacity = 0.2
        shadowLayer.shadowRadius = 0.0
        layer.addSublayer(shadowLayer)
    }
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(visualEffectView)
        addSubview(button)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            button.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 20.0),
            button.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 80.0),
            visualEffectView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 10.0),
            visualEffectView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 10.0),
            button.widthAnchor.constraint(equalToConstant: 50.0),
            button.heightAnchor.constraint(equalToConstant: 50.0),
        ])
    }
}
