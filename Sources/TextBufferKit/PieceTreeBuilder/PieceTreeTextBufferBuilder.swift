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

public class PieceTreeTextBufferBuilder<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Element: Hashable {
    var chunks: [StringBuffer<V>] = []
    var bom: V = V()
    
    var hasPreviousChar: Bool = false
    var previousChar: V.Element

    // setup
    private let newLine: V.Element  // \n
    private let lineFeed: V.Element // \r
    let bomIndicator: V

    // state
    var cr: Int = 0
    var lf: Int = 0
    var crlf: Int = 0

    init (previousChar: V.Element, newLine: V.Element, lineFeed: V.Element, bomIndicator: V)
    {
        self.previousChar = previousChar
        self.newLine = newLine
        self.lineFeed = lineFeed
        self.bomIndicator = bomIndicator
    }

    func startsWithUTF8BOM(_ data: V) -> Bool
    {
        guard data.count > bomIndicator.count else {
            return false
        }

        return V(data.prefix(bomIndicator.count)) == bomIndicator
    }

    public func acceptChunk(_ _chunk: V)
    {
        guard !_chunk.isEmpty else {
            return
        }

        var chunk = _chunk
        if chunks.isEmpty {
            if startsWithUTF8BOM(chunk) {
                bom = bomIndicator
                chunk = V (chunk [chunk.index(chunk.startIndex, offsetBy: bomIndicator.count)...])
            }
        }

        guard let lastChar = chunk.last else {
            return
        }

        if lastChar == lineFeed {
            // last character is \r
            acceptChunk1(V (chunk [chunk.startIndex..<chunk.index(before: chunk.endIndex)]), allowEmptyStrings: false)
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

        if (hasPreviousChar) {
            acceptChunk2 ([previousChar] + chunk)
        } else {
            acceptChunk2(chunk)
        }
    }

    func acceptChunk2(_ chunk: V)
    {
        let lineStarts = LineStarts(data: chunk, newLine: newLine, lineFeed: lineFeed)

        chunks.append (StringBuffer(buffer: chunk, lineStarts: lineStarts.lineStarts))
        cr += lineStarts.cr
        lf += lineStarts.lf
        crlf += lineStarts.crlf
    }

    public func finish(normalizeEol: Bool = true) -> PieceTreeTextBufferFactory<V> {
        finish()
        return PieceTreeTextBufferFactory(chunks: chunks, bom: bom, cr: cr, lf: lf, crlf: crlf, normalizeEol: normalizeEol, newLine: newLine, lineFeed: lineFeed)
    }

    func finish()
    {
        if chunks.isEmpty {
            acceptChunk1(V(), allowEmptyStrings: true)
        }

        if hasPreviousChar {
            hasPreviousChar = false
            // recreate last chunk
            let lastidx = chunks.index(before: chunks.endIndex)
            chunks[lastidx].buffer += [previousChar]
            let newLineStarts = LineStarts.createLineStartsArray(chunks [lastidx].buffer, newLine: newLine, lineFeed: lineFeed)
            chunks [lastidx].lineStarts = newLineStarts

            if (previousChar == lineFeed) {
                cr += 1
            }
        }
    }
}
