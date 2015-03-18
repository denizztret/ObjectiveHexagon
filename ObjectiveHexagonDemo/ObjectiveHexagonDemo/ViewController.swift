//
//  ViewController.swift
//  ObjectiveHexagonDemo
//
//  Created by Denis Tretyakov on 17.03.15.
//  Copyright (c) 2015 pythongem. All rights reserved.
//

import UIKit
import ObjectiveHexagonKit

let HEX_SIZE:   CGFloat = 58.0
let HEX_RADIUS: CGFloat = 45.0
let DATA_COUNT: Int     = 100

let DEBUG_DRAW = false
let CELL_IS_CIRCLE = false
let CELL_DRAW_TEXT = true

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var itemsGrid: HKHexagonGrid!
    var items: [HKHexagon]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Collection View
        if CELL_IS_CIRCLE {
            self.collectionView.registerClass(CollectionViewCellCircle.self, forCellWithReuseIdentifier: "CollectionViewCell")
        } else {
            self.collectionView.registerClass(CollectionViewCellHexagon.self, forCellWithReuseIdentifier: "CollectionViewCell")
        }
        
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        // Grid with Rectanglar Map
        let params = HKHexagonGrid.rectParamsForDataCount(DATA_COUNT, ratio: CGSizeMake(5, 4))
        let points = HKHexagonGrid.generateRectangularMap(params, convert: { (p) -> HKHexagonCoordinate3D in
            return hexConvertEvenRToCube(p)
        })
        
        self.itemsGrid = HKHexagonGrid(points: points, hexSize: HEX_SIZE, orientation: .Pointy, map: .Rectangle)
        
        // Items ordered by distance from central hex (cell)
        self.items = self.itemsGrid.hexesBySpirals()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: .CenteredVertically | .CenteredHorizontally, animated: false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}


extension ViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if CELL_IS_CIRCLE {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as CollectionViewCellCircle
            
            let hexObj = items[indexPath.item]
            cell.hexagon = hexObj
            cell.labelText = CELL_DRAW_TEXT ? hexObj.hashID : ""
            
            return cell
        } else {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as CollectionViewCellHexagon
            
            let hexObj = items[indexPath.item]
            cell.hexagon = hexObj
            cell.labelText = CELL_DRAW_TEXT ? hexObj.hashID : ""
            
            cell.borderWidth = 3.0
            cell.borderGapOuter = 5.0
            cell.borderColor = UIColor.brownColor()
            
            return cell
        }
    }
}


extension ViewController: UICollectionViewDelegate {
    
}
