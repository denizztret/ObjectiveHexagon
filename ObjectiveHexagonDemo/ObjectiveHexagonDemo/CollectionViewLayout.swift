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
    
    override func prepare() {
        super.prepare()
        
        if needUpdate {
            needUpdate = false
            
            self.grid.position = CGPoint.zero
            
            //MARK: Debug Draw Grid Frame
            if DEBUG_DRAW {
                self.collectionView!.DebugDrawRect(self.grid.frame, name: "frame", lineWidth: 1, strokeColor: UIColor.blue)
            }
            
            attributesByHash.removeAll(keepingCapacity: false)
            
            for (index, hex) in (items).enumerated() {
                let indexPath = IndexPath(item: index, section: 0)
                let attributes = self.layoutAttributesForItem(at: indexPath)
                attributesByHash[hex.hashID] = attributes
            }
        }
    }
    
    override var collectionViewContentSize : CGSize {
        return grid.contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var visibleElements = [UICollectionViewLayoutAttributes]()
        
        for (hashID, attributes) in attributesByHash {
            if attributes.frame.intersects(rect) {
                if let _ = grid.shape(byHashID: hashID) {
                    
                }
                visibleElements.append(attributes)
            }
        }
        
        return visibleElements
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let hex = items[indexPath.item]
        attributes.frame = hex.frame
        attributes.center = hex.center
        
        //MARK: Debug Draw Grid Cells
        if DEBUG_DRAW {
            self.collectionView!.DebugDrawPoly(hex.unwrappedVertices(), name: "Poly-\(hex.hashID)", lineWidth: 1, strokeColor: UIColor.brown)
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func finalizeCollectionViewUpdates() {
        needUpdate = true
        self.collectionView!.setNeedsLayout()
    }
}
