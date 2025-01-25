//
//  UIImage+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 23.12.24.
//

import UIKit.UIImage

extension UIImage {
    
    public static func animatedImage(withGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var gifDuration = 0.0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil),
               let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
               let frameDuration = gifInfo[kCGImagePropertyGIFDelayTime] as? NSNumber {
                gifDuration += frameDuration.doubleValue
            }
            
            let frameImage = UIImage(cgImage: cgImage)
            frames.append(frameImage)
        }
        
        return UIImage.animatedImage(with: frames, duration: gifDuration)
    }
}
