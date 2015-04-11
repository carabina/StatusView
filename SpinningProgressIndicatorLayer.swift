//
//  SpinningProgressIndicatorLayer.swift
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//  Swift version by Stefan Klieme.
//

import Cocoa

class SpinningProgressIndicatorLayer: CALayer {
    
    let RotationAnimationKey = "rotationAnimation"
    let FadeAnimationKey = "opacity"
//    let INDETERMINATE_FADE_ANIMATION = true
    
    struct FinGeometry {
        var bounds : CGRect = CGRectZero
        var anchorPoint : CGPoint = CGPointZero
        var position : CGPoint = CGPointZero
        var cornerRadius : CGFloat = 0.0
    }
    
    struct PieGeometry {
        var bounds : CGRect = CGRectZero
        var outerEdgeLength : CGFloat = 0.0
        var outlineWidth : CGFloat = 0.0
    }
    
    private var indeterminateCycleDuration : CFTimeInterval
    private var foreColor : CGColorRef!
    private var fullOpacity : Float
    private var indeterminateMinimumOpacity : Float
    private var numFins : UInt
    private var finLayersRoot : CALayer
    private var finLayers : Array<CALayer>
    private var finLayerRotationValues : Array<CGFloat>
    private var pieLayersRoot : CALayer
    private var pieOutline : CAShapeLayer!
    private var pieChartShape : CAShapeLayer!
    
    private var referenceSizeForShadowResizing  : CGSize {
        didSet {
            initialShadowRadius = self.shadowRadius
            initialShadowOffset = self.shadowOffset
            updateShadowDimensions()
        }
    }
    private var initialShadowRadius : CGFloat!
    private var initialShadowOffset : CGSize!
    
    var isRunning : Bool
    var isDeterminate : Bool = false {
            didSet {
               setupType()
        }
    }
    
    var color : NSColor  { // "copy" because we don't retain it -- we create a CGColor from it
        get { return NSColor(CGColor: foreColor)! }
        set {
            // Need to convert from NSColor to CGColor
            foreColor = newValue.CGColor
            
            // Update all of the fins to this new color, at once, immediately
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            for fin in finLayers {
                fin.backgroundColor = foreColor
            }
        
            if pieOutline != nil { pieOutline.strokeColor = foreColor }
            if pieChartShape != nil { pieChartShape.strokeColor = foreColor }
            
            CATransaction.commit()
        }
    }
    var resizeShadows : Bool
    
    var doubleValue : Double {
        didSet {
            if !determinateTweenTime.isNaN {
                CATransaction.begin()
                
                // This controls the transition from one doubleValue to the next.
                CATransaction.setAnimationDuration(determinateTweenTime)
            }
            
            pieChartShape.strokeEnd = CGFloat(doubleValue / maxValue)
            
            if !determinateTweenTime.isNaN {
                CATransaction.commit()
            }
        }
    }
    
    // For determinate-mode only.
    var maxValue : Double = 0.0
    
    var determinateProgressOpacity : Float {
        get { return pieChartShape.opacity }
        set { pieChartShape.opacity = newValue }
    }
    
    var determinateTweenTime : CFTimeInterval = 0.0 // Smoothes animation to new doubleValue. 0.0: disable smooth transition, hard jump.
    
    
    //MARK: - Init
    
    convenience override init()
    {
        self.init(indeterminateCycleDuration:CFTimeInterval(0.7), determinateTweenTime:CFTimeInterval.NaN) // Use Core Animation default.
    }
    
    init(indeterminateCycleDuration : CFTimeInterval, determinateTweenTime : CFTimeInterval)
    {
        self.indeterminateCycleDuration = indeterminateCycleDuration
        self.determinateTweenTime = determinateTweenTime
        self.numFins = 12
        finLayers = Array<CALayer>()
        finLayersRoot = CALayer()
        pieLayersRoot  = CALayer()
        //_finLayersRoot.anchorPoint = CGPointMake(0.5, 0.5) // This is the default.
        finLayerRotationValues = Array<CGFloat>()
        fullOpacity = 1.0
        indeterminateMinimumOpacity = 0.05
        isRunning = false
        resizeShadows = false
        isDeterminate = false
        maxValue = 100.0
        doubleValue = 0.0
        referenceSizeForShadowResizing = CGSizeMake(100.0, 100.0)
    
        super.init()
        self.color = NSColor.blackColor()
        self.addSublayer(finLayersRoot)
        self.bounds = CGRect(x:0.0, y:0.0, width:10.0, height:10.0)
        
        createFinLayers()
        createDeterminateLayers()
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeFinLayers()
    }
    
    //MARK: - Overrides

    override var bounds : CGRect
    {
        didSet {
            // Do the resizing all at once, immediately.
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            
            // Resize the fins.
            let finBounds = bounds
            var finGeo = finGeometryForBounds(finBounds)
            
            finLayersRoot.bounds = finBounds
            finLayersRoot.position = yrkCGRectGetCenter(finBounds)
            for fin in finLayers {
                fin.bounds = finGeo.bounds
                fin.anchorPoint = finGeo.anchorPoint
                fin.position = finGeo.position
                fin.cornerRadius = finGeo.cornerRadius
            }
            
            // Scale pie.
            var pieGeo = pieGeometryForBounds(bounds)
            let pieGeoBounds = pieGeo.bounds
            
            pieLayersRoot.bounds = pieGeoBounds
            pieLayersRoot.position = yrkCGRectGetCenter(pieGeoBounds)
            
            if pieOutline != nil {
                updatePieOutlineDimensionsForGeometry(pieOutline, pieGeo: pieGeo)
            }
            if pieChartShape != nil {
                updatePieChartDimensionsForGeometry(pieChartShape, pieGeo: pieGeo)
            }
            
            updateShadowDimensions()
            
            CATransaction.commit()
        }
    }
    
    func updateShadowDimensions()
    {
        if resizeShadows {
            let scaleFactors = shadowScaleFactorsForBounds(self.bounds)
            let scaleFactor = shorterDimensionForSize(scaleFactors)
            
            var scaledShadowOffset = initialShadowOffset
            scaledShadowOffset.width *= scaleFactor
            scaledShadowOffset.height *= scaleFactor
            
            shadowRadius = initialShadowRadius * scaleFactor
            shadowOffset = scaledShadowOffset
            
            // We could resize the sublayers’ shadows here.
        }
    }

    
    //MARK: - Animation
    
    func startProgressAnimation()
    {
        isRunning = true
        
        addSublayer(finLayersRoot)
        animateFinLayers()
    }
    
    func stopProgressAnimation()
    {
        isRunning = false
        
        deanimateFinLayers()
        finLayersRoot.removeFromSuperlayer()
    }
    
    func toggleProgressAnimation()
    {
        if isRunning {
            stopProgressAnimation()
        }
        else {
            startProgressAnimation()
        }
    }
    
    
    //MARK: - Helper Methods
    
    func setupType()
    {
        if isDeterminate {
            setupDeterminate()
        } else {
            setupIndeterminate()
        }
    }
    
    func setupIndeterminate()
    {
        pieLayersRoot.removeFromSuperlayer()
        addSublayer(finLayersRoot)
    }
    
    func setupDeterminate()
    {
        stopProgressAnimation()
        finLayersRoot.removeFromSuperlayer()
        addSublayer(pieLayersRoot)
    }
    
    func shadowScaleFactorsForBounds(newBounds : CGRect) -> CGSize
    {
        let initialSize = referenceSizeForShadowResizing
        var scaleFactors = newBounds.size
        scaleFactors.width /= initialSize.width
        scaleFactors.height /= initialSize.height
        return scaleFactors
    }

    func createFinLayers()
    {
        removeFinLayers()
        
        let selfBounds = self.bounds
        finLayersRoot.bounds = selfBounds
        finLayersRoot.position = yrkCGRectGetCenter(selfBounds)
        
        // Create new fin layers
        let finBounds = finLayersRoot.bounds
        let finGeo : FinGeometry = finGeometryForBounds(finBounds)
        
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        
        let rotationAngleBetweenFins : CGFloat =  CGFloat(M_PI) * -2.0 / CGFloat(numFins)
        
        finLayerRotationValues.removeAll()
        
        for index in 0..<numFins {
            let newFin = CALayer()
            
            let rotationAngle = rotationAngleBetweenFins * CGFloat(index)
            
            newFin.bounds = finGeo.bounds
            newFin.anchorPoint = finGeo.anchorPoint
            newFin.position = finGeo.position
            newFin.transform = CATransform3DMakeRotation(rotationAngle, 0.0, 0.0, 1.0)
            newFin.cornerRadius = finGeo.cornerRadius
            newFin.backgroundColor = foreColor
            
            finLayerRotationValues.append(rotationAngle)
            
            newFin.opacity = initialOpacityForFinAtIndex(index)
            
            finLayersRoot.addSublayer(newFin)
            finLayers.append(newFin)
        }
        
        CATransaction.commit()
    }

    func initialOpacityForFinAtIndex(index : UInt) -> Float
    {
        let fadePercent : CGFloat = 1.0 - CGFloat(index) /  CGFloat(numFins - 1)
        return indeterminateMinimumOpacity + ((fullOpacity - indeterminateMinimumOpacity) * Float(fadePercent))
    }
    
    func animateFinLayers()
    {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        deanimateFinLayers()
        
//        if INDETERMINATE_FADE_ANIMATION {
            var index : CFTimeInterval = 0
            
            for finLayer in finLayers {
                let now = finLayer.convertTime(CACurrentMediaTime(), fromLayer:nil)
                
                finLayer.opacity = indeterminateMinimumOpacity
                let fadeOut = CABasicAnimation(keyPath: FadeAnimationKey)
                fadeOut.fromValue = fullOpacity
                fadeOut.toValue = indeterminateMinimumOpacity
                
                fadeOut.duration = indeterminateCycleDuration
                let timeOffset : CFTimeInterval = indeterminateCycleDuration - (indeterminateCycleDuration * index / CFTimeInterval(numFins - 1))
                fadeOut.beginTime = now - timeOffset
                fadeOut.fillMode = kCAFillModeBackwards
                fadeOut.repeatCount = Float.infinity
                finLayer.addAnimation(fadeOut, forKey:FadeAnimationKey)
                index++
            }
//        } else {
//            let animation = CAKeyframeAnimation(keyPath:"transform.rotation.z")
//            animation.duration = indeterminateCycleDuration
//            animation.cumulative = false
//            animation.repeatCount = Float.infinity
//            animation.values = finLayerRotationValues
//            animation.removedOnCompletion = false
//            animation.calculationMode = kCAAnimationDiscrete
//            
//            finLayersRoot.addAnimation(animation, forKey:RotationAnimationKey)
//        }
        
        CATransaction.commit()
    }
    
    func deanimateFinLayers()
    {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        
//        if INDETERMINATE_FADE_ANIMATION {
            for finLayer in finLayers {
                finLayer.removeAnimationForKey(FadeAnimationKey)
            }
//        } else {
//            finLayersRoot.removeAnimationForKey(RotationAnimationKey)
//        }
        
        CATransaction.commit()
    }
    
    func removeFinLayers()
    {
        for finLayer in finLayers {
            finLayer.removeFromSuperlayer()
        }
        finLayers.removeAll()
    }
    
    // These are proportional to the size of the drawn determinate progress indicator.
    let OutlineWidthPercentage : CGFloat = 1.0 / 16.0
    let PieChartPaddingPercentage : CGFloat = (1.0 / 16.0 / 2.0) // The padding around the pie chart.
    let DeterminateLayersMarginPercentage : CGFloat = 0.98 // Selected to look good with current indeterminate settings.
    
    private func pieGeometryForBounds(bounds : CGRect) -> PieGeometry
    {
        var pieGeo =  PieGeometry()
        
        // Make sure the circles will fit the frame.
        
        var outerEdgeLength = shorterDimensionForSize(bounds.size)
        outerEdgeLength *= DeterminateLayersMarginPercentage
        let xInset = (bounds.width - outerEdgeLength) / 2.0
        let yInset = (bounds.height - outerEdgeLength) / 2.0
        
        pieGeo.outerEdgeLength = outerEdgeLength
        pieGeo.bounds = CGRectInset(bounds, xInset, yInset)
        pieGeo.outlineWidth = pieGeo.outerEdgeLength * OutlineWidthPercentage // This used to be rounded.
        return pieGeo
    }
    
    private func  updatePieOutlineDimensionsForGeometry(outlineShape : CAShapeLayer, pieGeo : PieGeometry)
    {
        let outlineInset = pieGeo.outlineWidth / 2
        let outlineRect = CGRectInset(pieGeo.bounds, outlineInset, outlineInset)
        
        var outlineTransform = CGAffineTransformForRotatingRectAroundCenter(outlineRect, angle:degreesToRadians(90.0))
        let outlineFlip = CGAffineTransformForScalingRectAroundCenter(outlineRect, sx:-1.0, sy:1.0) // Flip left<->right.
        outlineTransform = CGAffineTransformConcat(outlineTransform, outlineFlip)
        
        let outlinePath = CGPathCreateWithEllipseInRect(outlineRect, &outlineTransform)
        outlineShape.path = outlinePath
        
        outlineShape.lineWidth = pieGeo.outlineWidth
    }
    
    private func  updatePieChartDimensionsForGeometry(pieChartShape : CAShapeLayer, pieGeo : PieGeometry)
    {
        let outerRadius : CGFloat = pieGeo.outerEdgeLength / 2.0
        
        // The pie chart is drawn using a circular line
        // with a line width equal to twice the radius.
        // So we draw from every point on this line, which you can picture as a centerline,
        // radius units towards and away from the center, reaching the center exactly.
        // This way, we get a full circle, if the full length of the line is draw.
        let pieChartExtraInset : CGFloat = (pieGeo.outerEdgeLength * PieChartPaddingPercentage)
        let pieChartInset : CGFloat = (outerRadius + pieGeo.outlineWidth + pieChartExtraInset) / 2
        let pieChartCenterlineRadius : CGFloat = outerRadius - pieChartInset
        let pieChartOutlineRadius : CGFloat = pieChartCenterlineRadius * 2
        let pieChartRect : CGRect = CGRectInset(pieGeo.bounds, pieChartInset, pieChartInset)
        
        var pieChartTransform = CGAffineTransformForRotatingRectAroundCenter(pieChartRect, angle:degreesToRadians(90.0))
        let pieChartFlip = CGAffineTransformForScalingRectAroundCenter(pieChartRect, sx:-1.0, sy:1.0) // Flip left<->right.
        pieChartTransform = CGAffineTransformConcat(pieChartTransform, pieChartFlip)
        
        let pieChartPath = CGPathCreateWithEllipseInRect(pieChartRect, &pieChartTransform)
        pieChartShape.path = pieChartPath
        
        pieChartShape.lineWidth = pieChartOutlineRadius
    }
    
    func createDeterminateLayers()
    {
        removeDeterminateLayers()
        
        // Based on DRPieChartProgressView by David Rönnqvist:
        // https://github.com/JanX2/cocoaheads-coreanimation-samplecode
        
        let pieGeo = pieGeometryForBounds(self.bounds)
        
        let pieGeoBounds = pieGeo.bounds
        pieLayersRoot.bounds = pieGeoBounds
        pieLayersRoot.position = yrkCGRectGetCenter(pieGeoBounds)
        
        // Create new determinate layers.
        
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        
        let foregroundColor = foreColor
        let clearColor = CGColorGetConstantColor(kCGColorClear)
        
        // Calculate the radius for the outline. Since strokes are centered,
        // the shape needs to be inset half the stroke width.
        pieOutline = CAShapeLayer()
        pieOutline.opacity = fullOpacity
        updatePieOutlineDimensionsForGeometry(pieOutline!, pieGeo: pieGeo)
        
        // Draw only the line of the circular outline shape.
        pieOutline.fillColor =    clearColor
        pieOutline.strokeColor =  foregroundColor
        
        // Create the pie chart shape layer. It should fill from the center,
        // all the way out (excluding some extra space (equal to the width of
        // the outline)).
        pieChartShape = CAShapeLayer()
        pieChartShape.opacity = fullOpacity
        updatePieChartDimensionsForGeometry(pieChartShape, pieGeo: pieGeo)
        
        // We don't want to fill the pie chart since that will be visible
        // even when we change the stroke start and stroke end. Instead
        // we only draw the stroke with the width calculated above.
        pieChartShape.fillColor = clearColor
        pieChartShape.strokeColor = foregroundColor
        
        // Add sublayers.
        pieLayersRoot.addSublayer(pieOutline)
        pieLayersRoot.addSublayer(pieChartShape)
        
        pieChartShape.strokeStart = 0.0
        pieChartShape.strokeEnd = 0.0
        
        CATransaction.commit()
    }
    
    func removeDeterminateLayers()
    {
        if let sublayers = pieLayersRoot.sublayers {
            for pieLayer in sublayers {
                pieLayer.removeFromSuperlayer()
            }
        }
    }
    
    func  degreesToRadians(degrees : CGFloat) -> CGFloat
    {
        return degrees * CGFloat(M_PI) / 180.0
    }
    
    private func CGAffineTransformForRotatingRectAroundCenter(rect : CGRect, angle : CGFloat) -> CGAffineTransform
    {
        var transform = CGAffineTransformIdentity
        
        transform = CGAffineTransformTranslate(transform, CGRectGetMidX(rect), CGRectGetMidY(rect))
        transform = CGAffineTransformRotate(transform, angle)
        transform = CGAffineTransformTranslate(transform, -CGRectGetMidX(rect), -CGRectGetMidY(rect))
        
        return transform
    }
    
    private func CGAffineTransformForScalingRectAroundCenter(rect : CGRect, sx : CGFloat, sy : CGFloat)  -> CGAffineTransform
    {
        var transform = CGAffineTransformIdentity
        
        transform = CGAffineTransformTranslate(transform, CGRectGetMidX(rect), CGRectGetMidY(rect))
        transform = CGAffineTransformScale(transform, sx, sy)
        transform = CGAffineTransformTranslate(transform, -CGRectGetMidX(rect), -CGRectGetMidY(rect))
        
        return transform
    }
    
    private func finGeometryForBounds(bounds : CGRect) -> FinGeometry {
        let finBounds = finBoundsForBounds(bounds)
        return FinGeometry(bounds: finBounds,
            anchorPoint: finAnchorPoint(),
            position: CGPointMake(bounds.size.width / 2, bounds.size.height / 2),
            cornerRadius: finBounds.size.width / 2)
    }
    
    let FinWidthPercent : CGFloat = 0.095
    let FinHeightPercent : CGFloat = 0.30
    let FinAnchorPointVerticalOffsetPercent : CGFloat = -0.63 // Aesthetically pleasing value. Also indirectly determines margin.
    
    private func finBoundsForBounds(bounds : CGRect) -> CGRect {
        let size = bounds.size
        let minSide = shorterDimensionForSize(size)
        let width : CGFloat = minSide * FinWidthPercent
        let height : CGFloat = minSide * FinHeightPercent
        
        return CGRectMake(0, 0, width, height)
    }

    private func finAnchorPoint() -> CGPoint {
    // Horizentally centered, vertically offset.
        return CGPointMake(0.5, FinAnchorPointVerticalOffsetPercent)
    }
    
    private func yrkCGRectGetCenter(rect : CGRect) -> CGPoint {
        return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    }
    
    private func shorterDimensionForSize(size : CGSize ) -> CGFloat {
        return min(size.width, size.height);
    }

}
