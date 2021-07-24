//
//  PieceTreeTextBuffer.swift
//  TextBufferKit
//
//  Created by Miguel de Icaza on 8/16/19.
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
// https://github.com/microsoft/vscode/blob/master/src/vs/editor/common/model/pieceTreeTextBuffer/pieceTreeTextBuffer.ts
import Foundation

public class PieceTreeTextBuffer<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Element: Equatable {
    internal let pieceTree: PieceTreeBase<V>
    public internal(set) var bom: V
    public internal(set) var mightContainRTL: Bool
    public internal(set) var mightContainNonBasicASCII: Bool

    internal init(BOM: V, eol: V, pieceTree: PieceTreeBase<V>, containsRTL: Bool, isBasicASCII: Bool, eolNormalized: Bool)
    {
        self.bom = BOM
        self.mightContainNonBasicASCII = !isBasicASCII
        self.mightContainRTL = containsRTL
        self.pieceTree = pieceTree
    }
}

