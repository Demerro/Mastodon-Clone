//
//  CircularProgressView.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 30.05.25.
//

import UIKit
import UIKitFoundation
import SwiftUtilities

final class CircularProgressView: View {
    
    private static let lineWidth: CGFloat = 4.0
    
    private let progressLayer: CAShapeLayer = {
        $0.fillColor = UIColor.clear.cgColor
        $0.strokeColor = UIColor.tintColor.cgColor
        $0.lineWidth = lineWidth
        $0.lineCap = .round
        $0.strokeEnd = 0.0
        return $0
    }(CAShapeLayer())
    
    private let trackLayer: CAShapeLayer = {
        $0.fillColor = UIColor.clear.cgColor
        $0.strokeColor = UIColor.systemGray6.cgColor
        $0.lineWidth = lineWidth
        $0.lineCap = .round
        return $0
    }(CAShapeLayer())
    
    var progress: CGFloat = 0.0 {
        didSet {
            progress = clamp(progress, min: 0.0, max: 1.0)
            setNeedsDisplay()
        }
    }
    
    override func setupCommon() {
        super.setupCommon()
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0 - Self.lineWidth / 2.0
        
        let startAngle = -CGFloat.pi / 2.0
        let endAngle = startAngle + 2.0 * CGFloat.pi
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            progressLayer.strokeEnd = progress
        }
    }
}
