//
//  CollectionViewCell.swift
//  ObjectiveHexagonDemo
//
//  Created by Denis Tretyakov on 17.03.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import UIKit
import ObjectiveHexagonKit

class CollectionViewCellCircle: UICollectionViewCell {

    private var shapeLayer = CAShapeLayer()
    
    private var label: UILabel!
    var labelText = ""
    
    var hexagon: HKHexagon? {
        willSet {
            self.setNeedsLayout()
        }
    }
    
    private var shapeBounds: CGRect {
        let D_full: CGFloat = HEX_RADIUS * 2.0
        let D_half: CGFloat = HEX_RADIUS
        let size: CGSize = self.bounds.size
        return CGRectMake(size.width/2-D_half, size.height/2-D_half, D_full, D_full)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        self.contentView.backgroundColor = UIColor.clearColor()
        self.contentView.layer.shadowColor = UIColor.blackColor().CGColor;
        self.contentView.layer.shadowOffset = CGSizeMake(2, 1);
        self.contentView.layer.shadowOpacity = 0.5;
        self.contentView.layer.shadowRadius = 3;
        self.contentView.layer.allowsEdgeAntialiasing = true;
        
        self.shapeLayer.allowsEdgeAntialiasing = true
        self.contentView.layer.addSublayer(self.shapeLayer)
        
        self.label = UILabel()
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.label.backgroundColor = UIColor.clearColor()
        self.label.textAlignment = .Center
        self.label.font = UIFont(name: "Arial", size: 14)
        self.label.textColor = UIColor.grayColor()
        
        self.contentView.addSubview(self.label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(ovalInRect: shapeBounds)
        self.contentView.layer.shadowPath = path.CGPath
        self.shapeLayer.path = path.CGPath;
        self.shapeLayer.frame = self.bounds;
        
        if let hex = self.hexagon {
            let color = getColor(forCoordinate: hex.coordinate)
            self.shapeLayer.fillColor = color.CGColor
            
            self.label.frame = self.bounds
            self.label.text = labelText
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.hexagon = nil;
        self.label.text = nil;
    }
}

class CollectionViewCellHexagon: UICollectionViewCell {
    
    private var borderView = UIView()
    private var borderLayer = CAShapeLayer()
    
    private var label: UILabel!
    var labelText = ""
    
    var borderColor: UIColor = UIColor.brownColor() {
        didSet {
            borderLayer.strokeColor = self.borderColor.CGColor
        }
    }
    var borderWidth: CGFloat = 3.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var borderGapInner: CGFloat = 5.0 {
        didSet {
            setNeedsLayout()
        }
    }
    var borderGapOuter: CGFloat = 5.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var hexagon: HKHexagon? {
        willSet {
            self.setNeedsLayout()
        }
    }
    
    private var contentBounds: CGRect {
        if let hex = self.hexagon {
            let w = hex.grid.hexWidth
            let h = hex.grid.hexHeight
            
            return CGRectMake(0, 0, hex.frame.width, hex.frame.height)
        }
        return CGRectZero
    }
    
    private var contentCenter: CGPoint {
        if let hex = self.hexagon {
            return CGPoint(x: hex.frame.width/2, y: hex.frame.height/2)
        }
        return CGPointZero
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {

        self.layer.masksToBounds = false
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        
        borderView.clipsToBounds = true
        borderView.backgroundColor = UIColor.clearColor()
        
        borderLayer.fillColor = UIColor.clearColor().CGColor
        borderLayer.strokeColor = borderColor.CGColor
        
        borderView.layer.addSublayer(borderLayer)
        
        self.contentView.addSubview(borderView)
        
        self.label = UILabel()
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.label.backgroundColor = UIColor.clearColor()
        self.label.textAlignment = .Center
        self.label.font = UIFont(name: "Arial", size: 14)
        self.label.textColor = UIColor.grayColor()
        
        self.contentView.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let hex = self.hexagon {
            
            let borderSize = hex.grid.hexSize - borderGapOuter + borderWidth / 2
            let borderVertices = localVertices(borderSize)
            var borderPath = UIBezierPath()
            for i in 0..<borderVertices.count {
                if i == 0 { borderPath.moveToPoint(borderVertices[i]) }
                else { borderPath.addLineToPoint(borderVertices[i]) }
            }
            borderPath.closePath()
            
            borderLayer.path = borderPath.CGPath
            borderLayer.lineWidth = borderWidth / 2
            borderView.frame = contentBounds
            
            let color = getColor(forCoordinate: hex.coordinate)
            borderLayer.fillColor = color.CGColor
            
            self.label.frame = self.bounds
            self.label.text = labelText
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        hexagon = nil;
        label.text = nil;
    }
    
    func localVertices(size: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        if let hex = self.hexagon {
            for i in 0..<6 {
                let orVal = hex.grid.hexOrientation == HKHexagonGridOrientation.Pointy ? 1 : 0
                let angle = CGFloat(M_PI * Double(2 * i - orVal) / 6)
                let x = size * cos(angle)
                let y = size * sin(angle)
                var sc = CGPoint(x: x, y: y)
                sc = CGPointAdd(sc, contentCenter)
                points.append(sc)
            }
        }
        return points
    }
}