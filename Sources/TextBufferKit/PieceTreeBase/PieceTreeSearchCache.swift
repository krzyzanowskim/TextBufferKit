//
//  PieceTreeBase.swift
//  swift-textbuffer
//
//  Copyright 2019 Miguel de Icaza, Microsoft Corp
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

class PieceTreeSearchCache {
    var limit: Int
    var cache: [CacheEntry]

    public init (limit: Int)
    {
        self.limit = limit
        cache = []
    }

    public func get (offset: Int) -> CacheEntry? {
        for node in cache.reversed() {
            if (node.nodeStartOffset <= offset) && ((node.nodeStartOffset + node.node.piece.length) >= offset) {
                return node
            }
        }
        return nil
    }

    public func get2 (lineNumber: Int) -> CacheEntry? {
        for node in cache.reversed() {
            if let nodeStartLineNumber = node.nodeStartLineNumber {
                if nodeStartLineNumber < lineNumber && nodeStartLineNumber + (node.node.piece.lineFeedCount) >= lineNumber {
                    return node
                }
            }
        }
        return nil
    }

    /// Adds the element to the cache
    public func set (_ nodePosition: CacheEntry) {
        if cache.count >= limit {
            cache.removeFirst()
        }
        cache.append(nodePosition)
    }

    public func validate(offset: Int) {
        var hasInvalidVal = false
        var tmp: [CacheEntry?] = cache;
        let top = tmp.count
        var i = 0

        while i < top {
            let nodePos = tmp[i]!
            if nodePos.node.parent == nil || nodePos.nodeStartOffset >= offset {
                tmp[i] = nil
                hasInvalidVal = true;
            }
            i += 1
        }

        if hasInvalidVal {
            var newArr: [CacheEntry] = [];
            for entry in tmp {
                if let valid = entry {
                    newArr.append (valid)
                }
            }

            cache = newArr
        }
    }
}
