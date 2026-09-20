[![Platform](http://img.shields.io/badge/platform-iOS-blue.svg?style=flat)](https://github.com/denizztret/ObjectiveHexagon)
![Version](https://img.shields.io/badge/pod-v0.2.0-blue.svg?style=flat)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/denizztret/ObjectiveHexagon/blob/master/LICENSE)

<p align="center"><img src="https://github.com/denizztret/ObjectiveHexagon/blob/master/Screenshots/icon-blue-hexagon.png" height="200"/>
</p>

<h1 align="center">ObjectiveHexagon</h1>

Create and manage hexagonal shapes and grid. 
Based on the materials from http://www.redblobgames.com/grids/hexagons.

[<img src="https://github.com/denizztret/ObjectiveHexagon/blob/master/Screenshots/screens.png"/>](https://github.com/denizztret/ObjectiveHexagon/blob/master/Screenshots/screens.png)

## Requirements

- iOS 12.0+
- Xcode 12.0+ to run the included Playgrounds

## Installation

#### Using [CocoaPods](http://cocoapods.org)

Simply add the following line to your Podfile:

```ruby
pod 'ObjectiveHexagon', :git=>'https://github.com/denizztret/ObjectiveHexagon.git', :tag=>'0.2.0'
```
## Usage

See demo Swift app (_ObjectiveHexagonDemo_) and Playgrounds.

To use the playgrounds, first build the _ObjectiveHexagonKit_ framework using
the provided _Xcode_ target, then run the playground(s).

To build the _ObjectiveHexagonKit_ framework:

1. Select the _ObjectiveHexagonKit_ target, either in the the top of the _Xcode_ interface (next to the Run/Stop buttons), or by clicking on the `ObjectiveHexagonKit` folder in "Project Navigator", and then choosing _ObjectiveHexagonKit_ from the list of targets
1. On the menu bar, click "Product -> Build", or type "⌘ - B" on the keyboard
1. Once the _ObjectiveHexagonKit_ framework has built successfully, you will then be able to run any of the playgrounds that require it.

### List of Playgrounds
- HexagonCoordinates: Shows 3D hex coordinates calculated from a 2D position.
- HexagonGrid: Create a grid of hexagons drawn inside of a rectangular area
- HexagonShape: Create a hexagon shaped grid of hexagons
- TwoCenteredGrid: Create a grid of hexagons inside of a rectangle, with a 2nd
  rectangle showing a subset of the hexagon grid in a different color

