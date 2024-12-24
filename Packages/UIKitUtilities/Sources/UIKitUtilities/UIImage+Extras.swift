//
//  UIImage+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 23.12.24.
//

import UIKit.UIImage

extension UIImage {
    
    public func byPreparingThumbnail(ofSize size: CGSize, with displayScale: CGFloat) async -> UIImage? {
        guard let cgImage else { return nil }
        let scaledImage = UIImage(cgImage: cgImage, scale: displayScale, orientation: .up)
        let aspectRatio = scaledImage.size.width / scaledImage.size.height
        return await scaledImage.byPreparingThumbnail(ofSize: CGSize(width: size.height * aspectRatio, height: size.height))
    }
}
