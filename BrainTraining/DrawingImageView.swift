//
//  DrawingImageView.swift
//  BrainTraining
//
//  Created by Satish Bandaru on 07/08/21.
//

import UIKit

class DrawingImageView: UIImageView {
    
    weak var delegate: ViewController?
    var currentTouchPosition: CGPoint?
    
    func draw(from start: CGPoint, to end: CGPoint) {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        
        image = renderer.image { ctx in
            image?.draw(in: bounds)
            
            UIColor.black.setStroke()
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineWidth(15)
            
            ctx.cgContext.move(to: start)
            ctx.cgContext.addLine(to: end)
            ctx.cgContext.strokePath()
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        currentTouchPosition = touches.first?.location(in: self)
        
        // If previous drawing is still in process, cancel it
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let newTouchPoint = touches.first?.location(in: self) else {
            return
        }
        
        guard let previousTouchPoint = currentTouchPosition else { return }
        
        draw(from: previousTouchPoint, to: newTouchPoint)
        
        currentTouchPosition = newTouchPoint
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        currentTouchPosition = nil
        // Delay added to let users make one more stroke if needed.
        // For e.g. some users use 2 strokes for drawing 4, 7
        perform(#selector(numberDrawn), with: nil, afterDelay: 0.3)
    }
    
    @objc func numberDrawn() {
        guard let image = image else { return }
        
        // Need to convert the drawing to an image of size 28*28
        let drawRect = CGRect(x: 0, y: 0, width: 28, height: 28)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(bounds: drawRect, format: format)
        
        let imageWithBackground = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            image.draw(in: drawRect)
        }
        
        // Convert UIImage into a CIImage
        let ciImage = CIImage(cgImage: imageWithBackground.cgImage!)
        
        // attempt to create a color inversion filter
        if let filter = CIFilter(name: "CIColorInvert") {
            // give it our input CIImage
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            // create a context so we can perform conversion
            let context = CIContext(options: nil)
            
            // attempt to read the output CIImage
            if let outputImage = filter.outputImage {
                // attempt to convert that to a CGImage
                if let imageRef = context.createCGImage(outputImage, from: ciImage.extent) {
                    // attempt to convert *that* to a UIImage
                    let finalImage = UIImage(cgImage: imageRef)
                    
                    // and finally pass the finished image to our delegate
                    delegate?.numberDrawn(finalImage)
                }
            }
        }
    }
}
