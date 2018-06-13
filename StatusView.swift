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
        case none, processing, failed, caution, success
    }
    
    //MARK: - Structs
    
    struct ShapeColor {
        static let red = CGColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        static let orange = CGColor(red: 0.9, green: 0.7, blue: 0.0, alpha: 1.0)
        static let green = CGColor(red: 0.1, green: 0.8, blue: 0.2, alpha: 1.0)
        static let white = CGColor.white
        static let black = CGColor.black
        static let clear = CGColor.clear
        static let gray = CGColor(gray: 0.5, alpha: 0.75)
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
    
    var status : Status = .none {
        
        willSet {
            DispatchQueue.main.async {
                if newValue == .processing  {
                    self.startProgressIndicator()
                } else if newValue != .processing {
                    self.stopProgressIndicator()
                }
            }
        }
        didSet {
            DispatchQueue.main.async {
                self.updateLayerProperties()
            }
        }
    }
    
    @IBInspectable var inverted : Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.updateLayerProperties()
            }
        }
    }
    
    @IBInspectable var enabled : Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.updateLayerProperties()
            }
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
        let borderRect = viewRect.insetBy(dx: lineWidth * 0.8, dy: lineWidth * 0.8)
        borderLayer.path = CGPath(ellipseIn: borderRect, transform: nil)
        borderLayer.lineWidth = lineWidth
        borderLayer.frame = viewRect
        shapeLayer.frame = viewRect
        updateLayerProperties()
    }
    
    func updateLayerProperties()
    {
        switch status {
        case .none: shapeColor = ShapeColor.clear
        case .processing: shapeColor = ShapeColor.clear; enabled ? startProgressIndicator() : stopProgressIndicator()
        case .failed: shapeColor = enabled ? ShapeColor.red : ShapeColor.gray
        case .caution: shapeColor = enabled ? ShapeColor.orange : ShapeColor.gray
        case .success: shapeColor = enabled ? ShapeColor.green : ShapeColor.gray
        }
        borderLayer.fillColor = inverted ? shapeColor : nil
        borderLayer.strokeColor = shapeColor
        shapeLayer.strokeColor = inverted ? ShapeColor.white : shapeColor
        shapeLayer.fillColor = inverted ? ShapeColor.white : shapeColor
        let oneThird = oneThirdPosition
        let twoThird = twoThirdPosition
        
        let path = CGMutablePath()
        switch status {
        case .none, .processing:
            shapeLayer.path = nil
            return
            
        case .failed:
            path.move(to: CGPoint(x:oneThird, y:twoThird))
            path.addLine(to: CGPoint(x:twoThird, y:oneThird))
            path.move(to: CGPoint(x:oneThird, y:oneThird))
            path.addLine(to: CGPoint(x:twoThird, y:twoThird))
            
        case .caution:
            let xBottom = viewSideLength / 2
            path.addArc(center:CGPoint(x:xBottom, y:oneThird * 0.75), radius:lineWidth * 0.1, startAngle:.pi * 2.0, endAngle:0.0, clockwise:true)
            path.move(to: CGPoint(x:xBottom, y:oneThird * 1.3))
            path.addLine(to: CGPoint(x:xBottom, y:xBottom * 1.45))
            
        case .success:
            path.move(to: CGPoint(x:oneThird, y:(oneThird + viewSideLength / 9)))
            path.addLine(to: CGPoint(x:(oneThird + viewSideLength / 9), y:oneThird))
            path.addLine(to: CGPoint(x:twoThird, y:twoThird))
        }
        
        shapeLayer.path = CGPath(__byStroking: path, transform: nil, lineWidth: lineWidth, lineCap: CGLineCap.round, lineJoin: CGLineJoin.round, miterLimit: 0)
        
    }
    
    func startProgressIndicator()
    {
        if progressIndicatorLayer == nil {
            progressIndicatorLayer = SpinningProgressIndicatorLayer(indeterminateCycleDuration:1.5, determinateTweenTime:CFTimeInterval.infinity)
            progressIndicatorLayer.name = "progressIndicatorLayer"
            progressIndicatorLayer.anchorPoint = CGPoint.zero
            progressIndicatorLayer.bounds = CGRect(x: -lineWidth, y: -lineWidth, width: viewSideLength - lineWidth * 2, height: viewSideLength - lineWidth * 2)
            progressIndicatorLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            progressIndicatorLayer.zPosition = 10.0 // make sure it goes in front of the background layer
            self.mainLayer.addSublayer(self.progressIndicatorLayer)
            self.progressIndicatorLayer.startProgressAnimation()
        }
    }
    
    func stopProgressIndicator()
    {
        if progressIndicatorLayer != nil {
            self.progressIndicatorLayer.stopProgressAnimation()
            self.progressIndicatorLayer.removeFromSuperlayer()
            self.progressIndicatorLayer = nil
        }
    }
    
    func bindEnabled(to object : AnyObject, keyPath : String)
    {
        #if swift(>=3.3)
        bind(.enabled, to:object, withKeyPath:keyPath)
        #else
        bind(NSBindingName.enabled, to:object, withKeyPath:keyPath)
        #endif
    }
    
    func bindStatus(to object : AnyObject, keyPath : String)
    {
        #if swift(>=3.3)
        bind(NSBindingName(rawValue: "status"), to:object, withKeyPath:keyPath)
        #else
        bind("status", to:object, withKeyPath:keyPath)
        #endif
        
    }
    
    func bindHide(to object : AnyObject, keyPath : String)
    {
        #if swift(>=3.3)
        bind(.hidden, to:object, withKeyPath:keyPath)
        #else
        bind(NSBindingName.hidden, to:object, withKeyPath:keyPath)
        #endif
        
    }
}
