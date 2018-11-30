//
//  ViewController.swift
//  TrappingRainWater - an exploration of a popular interview question
//      No attempts have been made to be the most efficient solution(s).
//      I simply wanted to explore Neon
//
//  Created by drew curry on 2018-10-25.
//  Copyright © 2018 yinApps. All rights reserved.
//

import UIKit
import Neon
import SwifterSwift

class mainVC: UIViewController {

    @IBOutlet weak var mainWall: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var wallBlockLabel: UILabel!
    
    let stoneWallImage: UIImage = #imageLiteral(resourceName: "StoneWall.png")
    let waterWallImage: UIImage = #imageLiteral(resourceName: "WaterWall.png")
    //set to clear color in setup
    var emptyBlockImage: UIImage = UIImage()
    
    //preset row height, not sure how to best do this as yet
    let initWallRowHeight: CGFloat = 90.0
    var wallRowHeight: CGFloat = 90.0
    
    let mainInset: CGFloat = 10.0
    //until Neon accounts for new SafeArea, tack it on manually for top if in newer ios
    let safeAreaInsetAddition: CGFloat = 20.0
    let blockPadding: CGFloat = 1.0
    
    var blocks: [UIImageView] = []
    var wallRows: [UIView] = []
    
    //currentTopRow allows us to stack next row properly within a loop
    var currentTopRow: UIView? = nil
    
    var wallWidthInBlocks: Int = 0
    var wallHeightInBlocks: Int = 0
    
    //calc'd internal height reserved for blocks (used if over 6 rows in height)
    //   set after Neon fills UI with mainWall and title blocks
    var wallUsableHeightForBlocks: CGFloat = 0.0
    
    //THe MAIN determinant of the project, this builds the entire wall and structure
    //  and the string equivalent for label purposes
    let defaults = UserDefaults.standard
    var blocksMap: [Int] = [0,3,0,3,0]
    var blockString: String = ""
    
    var solutionCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupInitialUI()
        calcTrappedWater()
        
    }
    
    func calcTrappedWater() {
        //setupInitialUI()
        setupInitialSolutionValues()
        setupWallRows()
        
        //Two possible solutions:
        //one logical and easy for an interview, with graphical view
        processSolution()
        //one more esoteric in its thinking and only a debug print answer
        processSolutionViaVectors()

    }
    
}

extension mainVC {
    //manage solution functions
    func setupInitialSolutionValues() {
        
        mainWall.subviews.forEach { $0.removeFromSuperview() }
        //wallRows = []
        
        wallWidthInBlocks = blocksMap.count
        wallHeightInBlocks = blocksMap.max() ?? 0
        
        //adjust wallRowHeight (pixel height of row) if more than 6 blocks
        if (wallHeightInBlocks > 6) {
            wallUsableHeightForBlocks = mainWall.size.height - (titleLabel.size.height + wallBlockLabel.size.height + blockPadding)
            wallRowHeight = wallUsableHeightForBlocks / wallHeightInBlocks.cgFloat
        } else {
            wallRowHeight = initWallRowHeight
        }
        
        blocks = []
        wallRows  = []
        currentTopRow = nil
        
    }
}

extension mainVC {
    //manage UI
    func setupInitialUI() {
        
        //retrieve possibly stored blockmap
        getDefaults()
        
        let WallBlockLabelRecognizer = UITapGestureRecognizer()
        WallBlockLabelRecognizer.addTarget(self, action: #selector(showLabelEditor(tapGestureRecognizer:)))
        titleLabel.addGestureRecognizer(WallBlockLabelRecognizer)
        titleLabel.isUserInteractionEnabled = true

        var calcualatedTopInset: CGFloat = mainInset * 3
        if #available(iOS 11.0, *) {
            calcualatedTopInset += safeAreaInsetAddition
        }
        
        mainWall.fillSuperview(left: mainInset, right: mainInset, top: calcualatedTopInset, bottom: mainInset)
        titleLabel.anchorAndFillEdge(.top, xPad: 20, yPad: 20, otherSize: 100.0)
        wallBlockLabel.align(.underCentered, relativeTo: self.titleLabel!, padding: -30, width: mainWall.frame.size.width, height: 20)

        setWallBlockLabel()
        
        //need empty "image" to be same size as blocks
        emptyBlockImage = UIImage.init(color: mainWall.backgroundColor?.lighten() ?? .black, size: getStoneWallBlock().size)

    }
    
    func setupWallRows() {
        for _ in 1...wallHeightInBlocks {
            //build a row for each possible row as per block attributes
            _ = addWallRow(wall: mainWall)
        }
    }

}

extension mainVC {
    //manage gesture
    @objc func showLabelEditor(tapGestureRecognizer: UITapGestureRecognizer) {
        promptForAnswer()
    }
}

extension mainVC {
    //manage solutions
    
    func processSolution() {
        //setup WIP matrix that will be subtracted from with each pass to simulate walking down the wall
        solutionCount = 0
        var filling: Bool = false
        var lastRetainingBlock: Int = 0
        
        //blocksToAdd holds the potential  blocks that will be added should we encounter
        //  a retaining block, either empty or water
        var potentialBlocks: [UIView] = []
        var currentWallRow: UIView = UIView()
        
        print("processing: [ \(blockString) ]")
        
        for rowIndex in 1...wallHeightInBlocks {
            print("----------new row----------")
            potentialBlocks = []
            currentWallRow = wallRows[rowIndex-1]
            filling = false
            lastRetainingBlock = 0
            
            for columnIndex in 1...wallWidthInBlocks {
                print("-----------------------new col----------")
                print("row/col \(rowIndex, columnIndex)")
                if (rowIndex <= blocksMap[columnIndex-1]) {
                    // retaining block
                    
                    //drew: need way to backtrack and remove water blocks if we have no ending
                    
                    lastRetainingBlock = columnIndex
                    
                    
                    //filling may now be obsoleted
                    //if (potentialBlocks.count > 0 && filling) {
                    if (potentialBlocks.count > 0) {
                        //we are filling and hit a retaing block, so add in water blocks
                        //AddPotentialBlocks(wallRow: currentWallRow, potentialBlocks: potentialBlocks)
                        if (filling) {
                            print("filling potential blocks with water: \(potentialBlocks.count)")
                            AddPotentialBlocksAsFilled(wallRow: currentWallRow, potentialBlocks: potentialBlocks)

                        } else {
                            print("leaving potential blocks empty: \(potentialBlocks.count)")
                            AddPotentialBlocksAsEmpty(wallRow: currentWallRow, potentialBlocks: potentialBlocks)

                        }

                        //empty jug
                        potentialBlocks = []
                        
                    }
                    
                    //now add retaining block
                    print("adding stone block")
                    AddStoneBlockToWall(wallRow: currentWallRow)
                    filling = true
                    
                } else {
                    //empty block, so can be empty or filled depending on if we already
                    //  found a retaining block (indicated by filling = true
                    //  NOTE: no block at the ends can hold water
                    
                    //  augmented: never prefill with water. We must wait for another
                    //  retaining block before water gets added.
//                    if (filling && columnIndex > 0 && columnIndex < wallWidth) {
//                        potentialBlocks.append(getWaterWallBlock())
//                    } else {
//                        potentialBlocks.append(getEmptyWallBlock())
//                    }
                    print("adding potential block")
                    potentialBlocks.append(getEmptyWallBlock())
                    
                }
            }
            
            //when done row, check for no retaining wall encountered, and fill in as appropriate
            //  noting that if we here, we can no longer be filling.
            //trim off any non-retained blocks, shown if lastRetainingBlock < last column
            print("processing wall row: \(rowIndex)")

//design decision.. leave last empty columns for spacing purposes
//            if (lastRetainingBlock > 0 && lastRetainingBlock < wallWidth) {
//                var numBlocksToPop: Int = wallWidth - lastRetainingBlock
//
//                while (numBlocksToPop > 0) {
//                    potentialBlocks.pop()
//                    numBlocksToPop -= 1
//                }
//
////                for blockToRemove:Int in (wallWidth...lastRetainingBlock+1) {
////                    potentialBlocks.pop()
////                }
//            }
            
            if potentialBlocks.count > 0 {
                AddPotentialBlocksAsEmpty(wallRow: currentWallRow, potentialBlocks: potentialBlocks)
            }
            
            layoutWallRow(wallRow: currentWallRow)
            
        }
        
        //show solution
        self.titleLabel.text = "WaterBlocks: \(solutionCount)"
    }

    func processSolutionViaVectors() {
        //setup a sideways vector and convert to strings to manage solution
        
        //blocksToAdd holds the potential  blocks that will be added should we encounter
        //  a retaining block, either empty or water
        var vectoredString: String = ""
        var vectoredStrings: [String] = []
        
        //create a sidways-vectors set of strings to represent wall
        for rowIndex in 1...wallHeightInBlocks {
            vectoredString = ""
            for columnIndex in 1...wallWidthInBlocks {
                if (rowIndex <= blocksMap[columnIndex-1]) {
                    // retaining block
                    vectoredString += "*"
                    
                } else {
                    //empty block
                    vectoredString += " "
                }
            }
            //when done row, add vectored string to collection
            vectoredStrings.append(vectoredString)
        }
        
        //THIS WORKS, but is likey even more trimmable, BUT still requires building of UI
        
        let trimmedVectors: [String] = vectoredStrings.enumerated().map { (index, element) in
            let tmp: String  = element
            let tmp1: String = tmp.trimmingCharacters(in: .whitespaces)
            return (tmp1.count > 1) ? tmp1 : ""
        }
        
        //show solution
        solutionCount = trimmedVectors.map({($0 as String).filter { $0 == " " }.count}).sum()
        self.titleLabel.text = "WaterBlocks: \(solutionCount)"
        
        print("Per vector'd solution -> WaterBlocks count= \(solutionCount) blocks.")
    }
    
}

extension mainVC {
    //manage masonary for wall
    
    func addWallRow(wall: UIView) -> UIView {
        //main process to add a new row to the wall, calling get to create before managing it
        let newWallRow: UIView = getWallRow()
        
        //wall.addSubview(newWallRow)
        mainWall.addSubview(newWallRow)
        
        newWallRow.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: wallRowHeight)
        wallRows.append(newWallRow)
        
        return newWallRow
        
    }
    
    func getWallRow() -> UIView {
        return UIView()
    }

    func layoutWallRow(wallRow: UIView) {
        
        //subtle need to account for possible padding inside blocks, else the cumulative impact will
        //  make each row too wide. There will be block count plus 1 edges to accommodate.
        //  (CGFloat((wallWidthInBlocks+1)) * blockPadding)
        //TODO: proper accounting for padding between blocks AND width of wall not yet set.
        let blockPaddingCumulative = (CGFloat((wallWidthInBlocks+1)) * blockPadding)
        
        let blockWidth: CGFloat =
            (mainWall.frame.size.width) / CGFloat(wallWidthInBlocks)
        
        
        if (self.currentTopRow == nil) {
            //manage bottom row, which differs from the rest due to how Neon functions (no direct stacking methods yet
            wallRow.groupInCenter(group: .horizontal, views: wallRow.subviews, padding: blockPadding, width: blockWidth, height: wallRowHeight)
        } else {
            wallRow.align(.aboveCentered, relativeTo: self.currentTopRow!, padding: blockPadding, width: blockWidth, height: wallRowHeight)
            wallRow.groupInCenter(group: .horizontal, views: wallRow.subviews, padding: blockPadding, width: blockWidth, height: wallRowHeight)
            
        }
        finishWallRow(wallRow: wallRow)
        
    }
    
    func finishWallRow(wallRow: UIView) {
        //tell the masons where the top is:
        currentTopRow = wallRow
    }
    
    func AddStoneBlockToWall(wallRow: UIView) {
        print(">>>> adding stone to wall")
        wallRow.addSubview(getStoneWallBlock())
    }

    func AddPotentialBlocks(wallRow: UIView, potentialBlocks: [UIView]) {
        //drop whole collection of potential blocks into wall
        if potentialBlocks.count > 0 {
            wallRow.addSubviews(potentialBlocks)
        }
    }

    func AddPotentialBlocksAsEmpty(wallRow: UIView, potentialBlocks: [UIView]) {
        //we ran out of wall, so replace potential blocks with same count of empty blocks
        var emptyBlocks: [UIView] = []
        for _ in 1...potentialBlocks.count {
            print(">>>> adding empty block to wall")

            emptyBlocks.append(getEmptyWallBlock())
        }
        AddPotentialBlocks(wallRow: wallRow, potentialBlocks: emptyBlocks)
    }
    
    func AddPotentialBlocksAsFilled(wallRow: UIView, potentialBlocks: [UIView]) {
        //we ran into a retaining block while filling, so set potential blocks filled
        var filledBlocks: [UIView] = []
        for _ in 1...potentialBlocks.count {
            print(">>>> adding water block to wall")

            filledBlocks.append(getWaterWallBlock())
        }
        AddPotentialBlocks(wallRow: wallRow, potentialBlocks: filledBlocks)
    }

    func getStoneWallBlock() -> UIImageView {
        return UIImageView(image: stoneWallImage)
    }
    
    func getWaterWallBlock() -> UIImageView {
        print("inc count")
        solutionCount += 1
        return UIImageView(image: waterWallImage)
    }
    
    func getEmptyWallBlock() -> UIImageView {
        
        return UIImageView(image: emptyBlockImage)
    }
    
    func setWallBlock(newWallBlock: String) {
        
        let tmpBlocksMap = newWallBlock.replacingOccurrences(of: " ", with: "").split(separator: ",")
        self.blocksMap = tmpBlocksMap.map({ Int($0) ?? 0 })
        
        setWallBlockLabel()
    }
    
    func setWallBlockLabel() {
        let blocksMapStringArray: [String] = blocksMap.compactMap() { String($0) }
        blockString = blocksMapStringArray.joined(separator: ", ")
        wallBlockLabel.text =   "[ " +  blockString + " ]"
    }

}

extension mainVC {
    //obsoleted functions
    func buildWallRow(wallRow: UIView) {
        for _ in 1...wallWidthInBlocks {
            AddStoneBlockToWall(wallRow: wallRow)
        }
        
    }
    func AddEmptyBlockToWall(wallRow: UIView) {
        wallRow.addSubview(getEmptyWallBlock())
    }

}

extension mainVC {
    //utility
    func promptForAnswer() {
        let title = "Enter Wall Spec"
        let message = "Enter a new wall spec, like: 3,0,2,0,4 to build a 5-column wall with 3 blocks, no blocks etc. The app will calculate the water trapped in the wall."
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields?[0].text = blockString
        
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let answer: String = ac.textFields![0].text ?? ""
            // do something interesting with "answer" here
            
            self.setWallBlock(newWallBlock: answer)
            
            print("new map: \(self.blocksMap)")
            self.saveDefaults()
            
            self.calcTrappedWater()
            
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [unowned ac] _ in
            // do something interesting with "cancel" here?
        }
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        
        present(ac, animated: true)
    }
    
    func saveDefaults() {
        //simple util function to maintain continuity
        defaults.set(self.blocksMap, forKey: "blocksMap")
    }
    
    func getDefaults() {
        //simple util function to maintain continuity
        if let checkedBlockMap = defaults.object(forKey: "blocksMap") as? [Int] {
            self.blocksMap = checkedBlockMap
        }
    }

}
