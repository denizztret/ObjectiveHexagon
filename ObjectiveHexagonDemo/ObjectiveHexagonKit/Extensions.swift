//
//  Extensions.swift
//  ObjectiveHexagonDemo
//
//  Created by Denis Tretyakov on 24.02.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import UIKit

extension UIView {
    
    public func DebugDrawPoint(_ p:CGPoint, name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clear, diameter:CGFloat = 10.0) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if let oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        
        let pointLayer = CAShapeLayer()
        pointLayer.name = name
        pointLayer.path = ovalPath.cgPath
        pointLayer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        pointLayer.position = p
        pointLayer.fillColor = fillColor.cgColor
        pointLayer.strokeColor = strokeColor.cgColor
        pointLayer.lineWidth = lineWidth
        
        self.layer.addSublayer(pointLayer)
    }
    
    public func DebugDrawRect(_ rect:CGRect, name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clear) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if let oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        let rectPath = UIBezierPath(rect: rect)
        
        let rectLayer = CAShapeLayer()
        rectLayer.name = name
        rectLayer.path = rectPath.cgPath
        rectLayer.fillColor = fillColor.cgColor
        rectLayer.strokeColor = strokeColor.cgColor
        rectLayer.lineWidth = lineWidth
        
        self.layer.addSublayer(rectLayer)
    }
    
    public func DebugDrawPoly(_ points:[CGPoint], name:String, lineWidth:CGFloat, strokeColor:UIColor, fillColor:UIColor = UIColor.clear) {
        if self.layer.sublayers != nil {
            for layer in self.layer.sublayers! {
                if let oldLayer = layer as? CAShapeLayer {
                    if oldLayer.name != nil && oldLayer.name == name {
                        oldLayer.removeFromSuperlayer()
                    }
                }
            }
        }
        
        let polyPath = UIBezierPath()
        for i in 0..<points.count {
            if i == 0 { polyPath.move(to: points[i]) }
            else { polyPath.addLine(to: points[i]) }
        }
        polyPath.close()
        
        let polyLayer = CAShapeLayer()
        polyLayer.name = name
        polyLayer.path = polyPath.cgPath
        polyLayer.fillColor = fillColor.cgColor
        polyLayer.strokeColor = strokeColor.cgColor
        polyLayer.lineWidth = lineWidth
        self.layer.addSublayer(polyLayer)
    }
}

extension HKHexagonGrid {
    
    public func hexesBySpirals() -> [HKHexagon] {
        
        func maxDistance(_ hex: HKHexagon) -> Int {
            return Int(max(abs(hex.coordinate.x), abs(hex.coordinate.y), abs(hex.coordinate.z)))
        }
        
        let hexes = Array(self.hexes.values) as! [HKHexagon]
        let s = hexes.reduce(0) { max($0, maxDistance($1)) }
        
        var result = [HKHexagon]()
        
        for k in 0..<s {
            let shapes = self.shapes(atRing: UInt(k)) as! [HKHexagon]
            result += shapes
        }
        
        return result
    }
    
    public class func rectParamsForDataCount(_ cnt: Int, ratio: CGSize) -> HKHexagonGridRectParameters {
        
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
            if ratioW > ratioH { w1 += 1 }
            else { h1 += 1 }
            delta = w1 * h1 - count
        }
        
        param.maxQ = w1%2==0 ? w1/2 : (w1-1)/2
        param.minQ = -(w1 - param.maxQ - 1)
        param.maxR = h1%2==0 ? h1/2 : (h1-1)/2
        param.minR = -(h1 - param.maxR - 1)
        
        return param
    }
    
    public func boundsOfShapes(_ shapes: [HKHexagon], centerPoint: CGPoint) -> CGRect {
        let rect = self.bounds(ofShapes: shapes)
        return rect.offsetBy(dx: centerPoint.x, dy: centerPoint.y)
    }
}

extension HKHexagon {
    
    public func unwrappedVertices() -> [CGPoint] {
        let result = (self.vertices as! [NSValue]).map  {
            (value: NSValue) -> CGPoint in
            value.cgPointValue()
        }
        return result
    }
}

public func getColor(forCoordinate coord: HKHexagonCoordinate3D) -> UIColor {
    let r = abs(200-coord.x*100)/255.0;
    let g = abs(200-coord.y*100)/255.0;
    let b = abs(200-coord.z*100)/255.0;
    let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
    return color
}
