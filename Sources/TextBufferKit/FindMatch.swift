//
//  FindMatch.swift
//  TextBufferKit
//
//  Created by Miguel de Icaza on 8/19/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct FindMatch<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Index == Int {
    public var range: Range<V>
    public var matches: [V]?
}
