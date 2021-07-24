//
//  PieceTreeBase.swift
//  swift-textbuffer
//
//  Created by Miguel de Icaza on 8/10/19.
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

public struct PieceTreeSnapshot<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Element: Equatable {
    var pieces: [Piece]
    var index: Int
    var tree: PieceTreeBase<V>
    var bom: V

    public init (tree: PieceTreeBase<V>, bom: V)
    {
        pieces = []
        self.tree = tree
        self.bom = bom
        index = 0
        if tree.root !== TreeNode.SENTINEL{
            tree.iterate(node: tree.root, callback: { node in
                if node !== TreeNode.SENTINEL {
                    self.pieces.append(node.piece)
                }
                return true
            })
        }
    }

    public mutating func read() -> V?  {
        if pieces.count == 0 {
            if index == 0 {
                index += 1
                return bom
            } else {
                return nil
            }
        }

        if index > pieces.count - 1 {
            return nil
        }

        let idx  = index
        index += 1
        if index == 0 {
            return bom + tree.getPieceContent(piece: pieces[idx])
        }
        return tree.getPieceContent(piece: pieces[idx])
    }
}
