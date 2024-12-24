//
//  LayerView.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 4.12.24.
//

import UIKit

open class LayerView<Layer: CALayer>: View {
    
    public override final class var layerClass: AnyClass { Layer.self }
    
    public final var setLayer: Layer { layer as! Layer }
    
    open override func setupAfterLayoutSubviews() {
        super.setupAfterLayoutSubviews()
        setLayer.frame = bounds
    }
}
