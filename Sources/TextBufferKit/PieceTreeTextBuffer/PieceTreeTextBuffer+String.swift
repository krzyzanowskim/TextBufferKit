//
//  PieceTreeBuilder.swift
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

extension PieceTreeTextBuffer where V == String {
    
    convenience init(chunks: inout [StringBuffer<V>], BOM: V, eol: V, containsRTL: Bool, isBasicASCII: Bool, eolNormalized: Bool)
    {
        let pieceTree = PieceTreeBase(chunks: &chunks, eol: eol, eolNormalized: eolNormalized)
        self.init(BOM: BOM, eol: eol, pieceTree: pieceTree, containsRTL: containsRTL, isBasicASCII: isBasicASCII, eolNormalized: eolNormalized)
    }

    public var eol: V {
        get { pieceTree.eol }
        set {
            if newValue == "\n" || newValue == "\r\n" {
                pieceTree.eol = newValue
            }
        }
    }

    public static func == (lhs: PieceTreeTextBuffer<V>, rhs: PieceTreeTextBuffer<V>) -> Bool
    {
        if (lhs.bom != rhs.bom) {
            return false
        }
        if (lhs.eol != rhs.eol) {
            return false
        }
        return PieceTreeBase.equal (left: lhs.pieceTree, right: rhs.pieceTree)
    }

    public func createSnapshot (preserveBOM: Bool) -> PieceTreeSnapshot<V>
    {
        return pieceTree.createSnapshot(bom: preserveBOM ? bom: V())
    }

    public func getOffsetAt(lineNumber: Int, column: Int) ->  Int
    {
        return pieceTree.getOffsetAt(lineNumber, column)
    }

    public func delete (offset: Int, count: Int) {
        pieceTree.delete(offset: offset, cnt: count)
    }
}
