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

extension PieceTreeTextBufferBuilder where V == [UInt8] {

    public func acceptChunk(_ chunk: V)
    {
        if chunk.isEmpty {
            return
        }

        var chunk = chunk
        if chunks.isEmpty {
            if startsWithUTF8BOM(chunk) {
                bom = V ([0xeb, 0xbb, 0xbf])
                chunk = V (chunk [chunk.index(chunk.startIndex, offsetBy: bom.count)...])
            }
        }

        let lastChar = chunk.last
        if lastChar == 13 {
            // last character is \r
            acceptChunk1(V (chunk [chunk.startIndex...]), allowEmptyStrings: false)
            hasPreviousChar = true
            previousChar = lastChar
        } else {
            acceptChunk1(chunk, allowEmptyStrings: false)
            hasPreviousChar = false
            previousChar = lastChar
        }
    }

    func acceptChunk1(_ chunk: V, allowEmptyStrings: Bool) {
        if !allowEmptyStrings && chunk.isEmpty {
            // Nothing to do
            return
        }

        if hasPreviousChar, let previousChar = previousChar {
            acceptChunk2 ([previousChar] + chunk)
        } else {
            acceptChunk2(chunk)
        }
    }

    func acceptChunk2(_ chunk: V)
    {
        let lineStarts = LineStarts(data: chunk)

        chunks.append (StringBuffer(buffer: chunk, lineStarts: lineStarts.lineStarts))
        cr += lineStarts.cr
        lf += lineStarts.lf
        crlf += lineStarts.crlf
    }

    public func finish(normalizeEol: Bool = true) -> PieceTreeTextBufferFactory<V> {
        if chunks.isEmpty {
            acceptChunk1(V(), allowEmptyStrings: true)
        }

        if hasPreviousChar, let previousChar = previousChar {
            hasPreviousChar = false
            // recreate last chunk
            if let lastIndex = chunks.indices.last { // chunks.count - 1
                chunks[lastIndex].buffer.append(previousChar)
                let newLineStarts = createLineStartsArray(chunks [lastIndex].buffer)
                chunks [lastIndex].lineStarts = newLineStarts

                if (previousChar == 13) {
                    cr += 1
                }
            }

        }
        return PieceTreeTextBufferFactory(chunks: chunks, bom: bom, cr: cr, lf: lf, crlf: crlf, normalizeEol: normalizeEol)
    }
}

