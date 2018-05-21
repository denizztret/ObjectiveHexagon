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

    fileprivate var shapeLayer = CAShapeLayer()
    
    fileprivate var label: UILabel!
    var labelText = ""
    
    var hexagon: HKHexagon? {
        willSet {
            self.setNeedsLayout()
        }
    }
    
    fileprivate var shapeBounds: CGRect {
        let D_full: CGFloat = HEX_RADIUS * 2.0
        let D_half: CGFloat = HEX_RADIUS
        let size: CGSize = self.bounds.size
        return CGRect(x: size.width/2-D_half, y: size.height/2-D_half, width: D_full, height: D_full)
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
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.layer.shadowColor = UIColor.black.cgColor;
        self.contentView.layer.shadowOffset = CGSize(width: 2, height: 1);
        self.contentView.layer.shadowOpacity = 0.5;
        self.contentView.layer.shadowRadius = 3;
        self.contentView.layer.allowsEdgeAntialiasing = true;
        
        self.shapeLayer.allowsEdgeAntialiasing = true
        self.contentView.layer.addSublayer(self.shapeLayer)
        
        self.label = UILabel()
        self.label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.label.backgroundColor = UIColor.clear
        self.label.textAlignment = .center
        self.label.font = UIFont(name: "Arial", size: 14)
        self.label.textColor = UIColor.gray
        
        self.contentView.addSubview(self.label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(ovalIn: shapeBounds)
        self.contentView.layer.shadowPath = path.cgPath
        self.shapeLayer.path = path.cgPath;
        self.shapeLayer.frame = self.bounds;
        
        if let hex = self.hexagon {
            let color = getColor(forCoordinate: hex.coordinate)
            self.shapeLayer.fillColor = color.cgColor
            
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
    
    fileprivate var borderView = UIView()
    fileprivate var borderLayer = CAShapeLayer()
    
    fileprivate var label: UILabel!
    var labelText = ""
    
    var borderColor: UIColor = UIColor.brown {
        didSet {
            borderLayer.strokeColor = self.borderColor.cgColor
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
    
    fileprivate var contentBounds: CGRect {
        if let hex = self.hexagon {
            let w = hex.grid.hexWidth
            let h = hex.grid.hexHeight
            
            return CGRect(x: 0, y: 0, width: hex.frame.width, height: hex.frame.height)
        }
        return CGRect.zero
    }
    
    fileprivate var contentCenter: CGPoint {
        if let hex = self.hexagon {
            return CGPoint(x: hex.frame.width/2, y: hex.frame.height/2)
        }
        return CGPoint.zero
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
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        
        borderView.clipsToBounds = true
        borderView.backgroundColor = UIColor.clear
        
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        
        borderView.layer.addSublayer(borderLayer)
        
        self.contentView.addSubview(borderView)
        
        self.label = UILabel()
        self.label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.label.backgroundColor = UIColor.clear
        self.label.textAlignment = .center
        self.label.font = UIFont(name: "Arial", size: 14)
        self.label.textColor = UIColor.gray
        
        self.contentView.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let hex = self.hexagon {
            
            let borderSize = hex.grid.hexSize - borderGapOuter + borderWidth / 2
            let borderVertices = localVertices(borderSize)
            let borderPath = UIBezierPath()
            for i in 0..<borderVertices.count {
                if i == 0 { borderPath.move(to: borderVertices[i]) }
                else { borderPath.addLine(to: borderVertices[i]) }
            }
            borderPath.close()
            
            borderLayer.path = borderPath.cgPath
            borderLayer.lineWidth = borderWidth / 2
            borderView.frame = contentBounds
            
            let color = getColor(forCoordinate: hex.coordinate)
            borderLayer.fillColor = color.cgColor
            
            self.label.frame = self.bounds
            self.label.text = labelText
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        hexagon = nil;
        label.text = nil;
    }
    
    func localVertices(_ size: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        if let hex = self.hexagon {
            for i in 0..<6 {
                let orVal: CGFloat = hex.grid.hexOrientation == HKHexagonGridOrientation.pointy ? 1 : 0
                let angle = CGFloat.pi * (2 * CGFloat(i) - orVal) / 6
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
