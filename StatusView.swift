//
//  StatusView.swift
//
//  Created by Stefan Klieme on 01.01.15.
//
//

import Cocoa

class StatusView: NSView {
    
    //MARK: - Enums

    enum Status {
        case None, Processing, Failed, Caution, Success
    }
    
    //MARK: - Structs

    struct ShapeColor {
        static let red = CGColorCreateGenericRGB(1.0, 0.25, 0.25, 1.0)
        static let orange = CGColorCreateGenericRGB(0.9, 0.7, 0.0, 1.0)
        static let green = CGColorCreateGenericRGB(0.1, 0.8, 0.2, 1.0)
        static let white = CGColorGetConstantColor(kCGColorWhite)
        static let black = CGColorGetConstantColor(kCGColorBlack)
        static let clear = CGColorGetConstantColor(kCGColorClear)
        static let gray = CGColorCreateGenericGray(0.5, 0.75)
    }
    
    //MARK: - Variables
    //MARK: Objects

    var mainLayer : CALayer!
    let borderLayer = CAShapeLayer()
    let shapeLayer = CAShapeLayer()
    var shapeColor : CGColor!
    var progressIndicatorLayer : SpinningProgressIndicatorLayer!

    //MARK: Geometric parameters
    
    var viewSideLength : CGFloat = 0.0
    var lineWidth : CGFloat = 0.0
    
    var oneThirdPosition : CGFloat {
        return (viewSideLength / 3.0) + lineWidth / 3.0
    }
    
    var twoThirdPosition : CGFloat {
        return (viewSideLength * 2.0 / 3.0) - lineWidth / 3.0
    }
    
    //MARK: Appearance
    
    var status : Status = .None {
        willSet {
            if newValue == .Processing  {
                startProgressIndicator()
            } else if newValue != .Processing {
                stopProgressIndicator()
            }
        }
        didSet {
            updateLayerProperties()
        }
    }
    
    @IBInspectable var inverted : Bool = false {
        didSet {
            updateLayerProperties()
        }
    }

    @IBInspectable var enabled : Bool = true {
        didSet {
            updateLayerProperties()
        }
    }
    
    //MARK: - Init
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        mainLayer = layer!
        mainLayer.addSublayer(borderLayer)
        mainLayer.addSublayer(shapeLayer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        wantsLayer = true
        mainLayer = layer!
        mainLayer.addSublayer(borderLayer)
        mainLayer.addSublayer(shapeLayer)
    }
    
    //MARK: - Redraw methods

    override func layout()
    {
        super.layout()
        viewSideLength = min(frame.width, frame.height)
        lineWidth = viewSideLength / 14.0
        let viewRect = CGRect(x: 0.0 , y: 0.0, width: viewSideLength, height: viewSideLength)
        let borderRect = CGRectInset(viewRect, lineWidth * 0.8, lineWidth * 0.8)
        borderLayer.path = CGPathCreateWithEllipseInRect(borderRect, nil)
        borderLayer.lineWidth = lineWidth
        borderLayer.frame = viewRect
        shapeLayer.frame = viewRect
        updateLayerProperties()
    }
    
    func updateLayerProperties()
    {
        switch status {
            case .None: shapeColor = ShapeColor.clear
            case .Processing: shapeColor = ShapeColor.clear; enabled ? startProgressIndicator() : stopProgressIndicator()
            case .Failed: shapeColor = enabled ? ShapeColor.red : ShapeColor.gray
            case .Caution: shapeColor = enabled ? ShapeColor.orange : ShapeColor.gray
            case .Success: shapeColor = enabled ? ShapeColor.green : ShapeColor.gray
        }
        borderLayer.fillColor = inverted ? shapeColor : nil
        borderLayer.strokeColor = shapeColor
        shapeLayer.strokeColor = inverted ? ShapeColor.white : shapeColor
        shapeLayer.fillColor = inverted ? ShapeColor.white : shapeColor
        let oneThird = oneThirdPosition
        let twoThird = twoThirdPosition
        
        var path = CGPathCreateMutable()
        switch status {
        case .None, .Processing:
            shapeLayer.path = nil
            return
            
        case .Failed:
            CGPathMoveToPoint(path, nil, oneThird, twoThird)
            CGPathAddLineToPoint(path, nil, twoThird, oneThird)
            CGPathMoveToPoint(path, nil, oneThird, oneThird)
            CGPathAddLineToPoint(path, nil, twoThird, twoThird)
            
        case .Caution:
            let xBottom = viewSideLength / 2
            CGPathAddArc(path, nil, xBottom, oneThird * 0.75, lineWidth * 0.1, CGFloat(M_PI) * 2.0, 0.0, true)
            CGPathMoveToPoint(path, nil, xBottom, oneThird * 1.3)
            CGPathAddLineToPoint(path, nil, xBottom, xBottom * 1.45)
            
        case .Success:
            CGPathMoveToPoint(path, nil, oneThird, (oneThird + viewSideLength / 9))
            CGPathAddLineToPoint(path, nil, (oneThird + viewSideLength / 9), oneThird)
            CGPathAddLineToPoint(path, nil, twoThird, twoThird)
        }
        
        shapeLayer.path = CGPathCreateCopyByStrokingPath(path, nil, lineWidth, kCGLineCapRound, kCGLineJoinRound, 0)

    }
    
    func startProgressIndicator()
    {
        if progressIndicatorLayer == nil {
            progressIndicatorLayer = SpinningProgressIndicatorLayer(indeterminateCycleDuration:1.5, determinateTweenTime:CFTimeInterval.infinity)
            progressIndicatorLayer.name = "progressIndicatorLayer"
            progressIndicatorLayer.anchorPoint = CGPointZero
            progressIndicatorLayer.bounds = CGRect(x: -lineWidth, y: -lineWidth, width: viewSideLength - lineWidth * 2, height: viewSideLength - lineWidth * 2)
            progressIndicatorLayer.autoresizingMask = .LayerWidthSizable | .LayerHeightSizable
            progressIndicatorLayer.zPosition = 10.0 // make sure it goes in front of the background layer
            mainLayer.addSublayer(progressIndicatorLayer)
            progressIndicatorLayer.startProgressAnimation()
        }
    }
    
    func stopProgressIndicator()
    {
        if progressIndicatorLayer != nil {
            progressIndicatorLayer.stopProgressAnimation()
            progressIndicatorLayer.removeFromSuperlayer()
            progressIndicatorLayer = nil
        }

    }
}
