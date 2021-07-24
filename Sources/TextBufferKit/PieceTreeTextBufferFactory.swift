//
//  PieceTreeBuilder.swift
//  swift-textbuffer
//
//  Created by Miguel de Icaza on 8/15/19.
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

public class PieceTreeTextBufferFactory<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> {
    var chunks: [StringBuffer<V>]
    var bom: V
    var cr, lf, crlf: Int
    var normalizeEol: Bool
    var containsRtl: Bool = false
    var isBasicAscii: Bool = false

    init(chunks: [StringBuffer<V>], bom: V, cr: Int, lf: Int, crlf: Int, normalizeEol:Bool, containsRtl: Bool? = nil, isBasicAscii: Bool? = nil)
    {
        self.chunks = chunks
        self.bom = bom
        self.cr = cr
        self.lf = lf
        self.crlf = crlf
        self.normalizeEol = normalizeEol
        self.containsRtl = containsRtl ?? false
        self.isBasicAscii = isBasicAscii ?? false
    }

    public func getFirstLineText(upTo index: V.Index? = nil) -> V {
        guard let firstBuffer = chunks.first?.buffer else {
            return V()
        }
        return V(firstBuffer[..<(index ?? firstBuffer.endIndex)])
        // TODO
        // return chunks[0].buffer.substr(0, 100).split(/\r\n|\r|\n/)[0];
    }
}
