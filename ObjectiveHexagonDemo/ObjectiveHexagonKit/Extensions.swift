//
//  Extensions.swift
//  ObjectiveHexagonDemo
//
//  Created by Denis Tretyakov on 24.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import UIKit

extension UIView {
    
    public func DebugDrawPoint(p:CGPoint, name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clearColor(), diameter:CGFloat = 10.0) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if var oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        var ovalPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, diameter, diameter))
        
        var pointLayer = CAShapeLayer()
        pointLayer.name = name
        pointLayer.path = ovalPath.CGPath
        pointLayer.bounds = CGRectMake(0, 0, diameter, diameter)
        pointLayer.position = p
        pointLayer.fillColor = fillColor.CGColor
        pointLayer.strokeColor = strokeColor.CGColor
        pointLayer.lineWidth = lineWidth
        
        self.layer.addSublayer(pointLayer)
    }
    
    public func DebugDrawRect(rect:CGRect, name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clearColor()) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if var oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        var rectPath = UIBezierPath(rect: rect)
        
        var rectLayer = CAShapeLayer()
        rectLayer.name = name
        rectLayer.path = rectPath.CGPath
        rectLayer.fillColor = fillColor.CGColor
        rectLayer.strokeColor = strokeColor.CGColor
        rectLayer.lineWidth = lineWidth
        
        self.layer.addSublayer(rectLayer)
    }
    
    public func DebugDrawPoly(points:[CGPoint], name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clearColor()) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if var oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        var polyPath = UIBezierPath()
        for i in 0..<points.count {
            if i == 0 { polyPath.moveToPoint(points[i]) }
            else { polyPath.addLineToPoint(points[i]) }
        }
        polyPath.closePath()
        
        var polyLayer = CAShapeLayer()
        polyLayer.name = name
        polyLayer.path = polyPath.CGPath
        polyLayer.fillColor = fillColor.CGColor
        polyLayer.strokeColor = strokeColor.CGColor
        polyLayer.lineWidth = lineWidth
        self.layer.addSublayer(polyLayer)
    }
}

extension HKHexagonGrid {
    
    public func hexesBySpirals() -> [HKHexagon] {
        
        func maxDistance(hex: HKHexagon) -> Int {
            return Int(max(fabs(hex.coordinate.x), fabs(hex.coordinate.y), fabs(hex.coordinate.z)))
        }
        
        let hexes = Array(self.hexes.values) as! [HKHexagon]
        let s = hexes.reduce(0) { max($0, maxDistance($1)) }
        
        var result = [HKHexagon]()
        
        for k in 0..<s {
            let shapes = self.shapesAtRing(UInt(k)) as! [HKHexagon]
            result += shapes
        }
        
        return result
    }
    
    public class func rectParamsForDataCount(cnt: Int, ratio: CGSize) -> HKHexagonGridRectParameters {
        
        var param = HKHexagonGridRectParameters(minQ: 0, maxQ: 0, minR: 0, maxR: 0)
        
        let count = cnt + 1
        let ratioW = ratio.width
        let ratioH = ratio.height
        
        let x = sqrt(CGFloat(count) / (ratioW * ratioH))
        let w = x * ratioW
        let h = x * ratioH
        
        var w1 = Int(round(w))
        var h1 = Int(round(h))
        
        var delta = w1 * h1 - count
        while delta < 0 {
            if ratioW > ratioH { w1++ }
            else { h1++ }
            delta = w1 * h1 - count
        }
        
        param.maxQ = w1%2==0 ? w1/2 : (w1-1)/2
        param.minQ = -(w1 - param.maxQ - 1)
        param.maxR = h1%2==0 ? h1/2 : (h1-1)/2
        param.minR = -(h1 - param.maxR - 1)
        
        return param
    }
    
    public func boundsOfShapes(shapes: [HKHexagon], centerPoint: CGPoint) -> CGRect {
        let rect = self.boundsOfShapes(shapes)
        return CGRectOffset(rect, centerPoint.x, centerPoint.y)
    }
}

extension HKHexagon {
    
    public func unwrappedVertices() -> [CGPoint] {
        let result = (self.vertices as! [NSValue]).map  {
            (value: NSValue) -> CGPoint in
            value.CGPointValue()
        }
        return result
    }
}

public func getColor(forCoordinate coord: HKHexagonCoordinate3D) -> UIColor {
    let r = fabs(200-coord.x*100)/255.0;
    let g = fabs(200-coord.y*100)/255.0;
    let b = fabs(200-coord.z*100)/255.0;
    let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
    return color
}