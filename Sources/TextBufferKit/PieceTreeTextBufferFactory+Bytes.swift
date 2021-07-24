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

extension PieceTreeTextBufferFactory where V == [UInt8] {
    //
    // returns an array of either '\r\n' | '\n'
    //
    func getEOL(_ defaultEOL: DefaultEndOfLine) -> V {
        let totalEOLCount = cr + lf + crlf
        let totalCRCount = cr + crlf
        if (totalEOLCount == 0) {
            // This is an empty file or a file with precisely one line
            return (defaultEOL == .LF ? [10] : [13, 10])
        }
        if (totalCRCount > totalEOLCount / 2) {
            // More than half of the file contains \r\n ending lines
            return [13, 10];
        }
        // At least one line more ends in \n
        return [10]
    }

    public func createPieceTreeBase (_ defaultEOL: DefaultEndOfLine = .LF) -> PieceTreeBase<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == [13, 10] && (cr > 0 || lf > 0)) || (eol == [10] && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = createLineStartsArray(str)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeBase<V>(chunks: &chunks, eol: eol, eolNormalized: normalizeEol)
    }

    public func create (_ defaultEOL: DefaultEndOfLine = .LF) -> PieceTreeTextBuffer<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == [13, 10] && (cr > 0 || lf > 0)) || (eol == [10] && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = createLineStartsArray(str)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeTextBuffer(chunks: &chunks, BOM: bom, eol: eol, containsRTL: containsRtl, isBasicASCII: isBasicAscii, eolNormalized: normalizeEol)
    }
}
