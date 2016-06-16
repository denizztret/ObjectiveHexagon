//
//  CollectionViewLayout.swift
//  ObjectiveHexagonDemo
//
//  Created by Denis Tretyakov on 17.03.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import UIKit
import ObjectiveHexagonKit

class CollectionViewLayout: UICollectionViewLayout {
    
    var grid: HKHexagonGrid { get { return (self.collectionView!.dataSource! as! ViewController).itemsGrid } }
    var items: [HKHexagon] { get { return (self.collectionView!.dataSource! as! ViewController).items } }
    
    var attributesByHash = [String : UICollectionViewLayoutAttributes]()
    var needUpdate = true
    
    override func prepareLayout() {
        super.prepareLayout()
        
        if needUpdate {
            needUpdate = false
            
            self.grid.position = CGPointZero
            
            //MARK: Debug Draw Grid Frame
            if DEBUG_DRAW {
                self.collectionView!.DebugDrawRect(self.grid.frame, name: "frame", lineWidth: 1, strokeColor: UIColor.blueColor())
            }
            
            attributesByHash.removeAll(keepCapacity: false)
            
            for (index, hex) in (items).enumerate() {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                let attributes = self.layoutAttributesForItemAtIndexPath(indexPath)
                attributesByHash[hex.hashID] = attributes
            }
        }
    }
    
    override func collectionViewContentSize() -> CGSize {
        return grid.contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var visibleElements = [UICollectionViewLayoutAttributes]()
        
        for (hashID, attributes) in attributesByHash {
            if CGRectIntersectsRect(attributes.frame, rect) {
                if let hex = grid.shapeByHashID(hashID) {
                    
                }
                visibleElements.append(attributes)
            }
        }
        
        return visibleElements
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        let hex = items[indexPath.item]
        attributes.frame = hex.frame
        attributes.center = hex.center
        
        //MARK: Debug Draw Grid Cells
        if DEBUG_DRAW {
            self.collectionView!.DebugDrawPoly(hex.unwrappedVertices(), name: "Poly-\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.brownColor())
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func finalizeCollectionViewUpdates() {
        needUpdate = true
        self.collectionView!.setNeedsLayout()
    }
}
