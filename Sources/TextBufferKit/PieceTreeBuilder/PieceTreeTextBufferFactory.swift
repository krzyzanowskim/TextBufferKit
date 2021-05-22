//
//  PieceTreeBuilder.swift
//  swift-textbuffer
//
//  Created by Miguel de Icaza on 8/15/19.
//  Copyright 2019 Miguel de Icaza, Microsoft Corp, Marcin Krzyzanowski
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

    private let newLine: V.Element  // \n
    private let lineFeed: V.Element // \r

    init(chunks: [StringBuffer<V>], bom: V, cr: Int, lf: Int, crlf: Int, normalizeEol:Bool, containsRtl: Bool? = nil, isBasicAscii: Bool? = nil, newLine: V.Element, lineFeed: V.Element)
    {
        self.chunks = chunks
        self.bom = bom
        self.cr = cr
        self.lf = lf
        self.crlf = crlf
        self.normalizeEol = normalizeEol
        self.containsRtl = containsRtl ?? false
        self.isBasicAscii = isBasicAscii ?? false
        self.newLine = newLine
        self.lineFeed = lineFeed
    }
}

extension PieceTreeTextBufferFactory where V == [UInt8] {
    //
    // returns an array of either '\r\n' | '\n'
    //
    func getEOL(_ defaultEOL: EndOfLine<V>) -> EndOfLine<V> {
        let totalEOLCount = cr + lf + crlf
        let totalCRCount = cr + crlf
        if (totalEOLCount == 0) {
            // This is an empty file or a file with precisely one line
            //return (defaultEOL == .LF ? [10] : [13, 10])
            return defaultEOL
        }
        if (totalCRCount > totalEOLCount / 2) {
            // More than half of the file contains \r\n ending lines
            return EndOfLine.CRLF
        }
        // At least one line more ends in \n
        return EndOfLine.LF
    }

    public func createPieceTreeBase (_ defaultEOL: EndOfLine<V> = .LF) -> PieceTreeBase<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == .CRLF && (cr > 0 || lf > 0)) || (eol == .LF && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = LineStarts.createLineStartsArray(str, newLine: newLine, lineFeed: lineFeed)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeBase(chunks: &chunks, eol: eol, eolNormalized: normalizeEol, newLine: newLine, lineFeed: lineFeed)
    }

    public func create (_ defaultEOL: EndOfLine<V> = .LF) -> PieceTreeTextBuffer<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == .CRLF && (cr > 0 || lf > 0)) || (eol == .LF && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = LineStarts.createLineStartsArray(str, newLine: newLine, lineFeed: lineFeed)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeTextBuffer(chunks: &chunks, BOM: bom, eol: eol, containsRTL: containsRtl, isBasicASCII: isBasicAscii, eolNormalized: normalizeEol, newLine: newLine, lineFeed: lineFeed)
    }


    public func getFirstLineText(lengthLimit: Int) -> V {
        return V (chunks [0].buffer [0..<lengthLimit])
        // TODO
        // return chunks[0].buffer.substr(0, 100).split(/\r\n|\r|\n/)[0];
    }
}
