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

let bomArray: [UInt8] = [0xeb, 0xbb, 0xbf]

func startsWithUTF8BOM<V: RangeReplaceableCollection & BidirectionalCollection & Hashable>(_ str: V) -> Bool where V.Index == Int, V.Element == UInt8
{
    // UTF8-BOM 0xEF,0xBB,0xBF
    guard str.count > 2 else {
        return false
    }

    return (Int(str [0]) == 0xeb && Int (str [1]) == 0xbb && Int (str [2]) == 0xbf)
}

func startsWithUTF8BOM<V: StringProtocol>(_ str: V) -> Bool
{
    // UTF8-BOM 0xEF,0xBB,0xBF
    guard str.count > 2 else {
        return false
    }

    return Array(str.utf8.prefix(bomArray.count)) == bomArray
}

public class PieceTreeTextBufferFactory<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Index == Int {
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
}

extension PieceTreeTextBufferFactory where V == [UInt8] {
    //
    // returns an array of either '\r\n' | '\n'
    //
    func getEOL(_ defaultEOL: DefaultEndOfLine<V>) -> DefaultEndOfLine<V> {
        let totalEOLCount = cr + lf + crlf
        let totalCRCount = cr + crlf
        if (totalEOLCount == 0) {
            // This is an empty file or a file with precisely one line
            //return (defaultEOL == .LF ? [10] : [13, 10])
            return defaultEOL
        }
        if (totalCRCount > totalEOLCount / 2) {
            // More than half of the file contains \r\n ending lines
            return DefaultEndOfLine.CRLF
        }
        // At least one line more ends in \n
        return DefaultEndOfLine.LF
    }

    public func createPieceTreeBase (_ defaultEOL: DefaultEndOfLine<V> = .LF) -> PieceTreeBase<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == .CRLF && (cr > 0 || lf > 0)) || (eol == .LF && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = LineStarts.createLineStartsArray(str)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeBase(chunks: &chunks, eol: eol, eolNormalized: normalizeEol)
    }

    public func create (_ defaultEOL: DefaultEndOfLine<V> = .LF) -> PieceTreeTextBuffer<V>
    {
        let eol = getEOL(defaultEOL)
        var chunks = self.chunks

        if normalizeEol && ((eol == .CRLF && (cr > 0 || lf > 0)) || (eol == .LF && (cr > 0 || crlf > 0))) {
            // Normalize pieces
            for i in 0..<chunks.count {
                // TODO
                // let str = chunks[i].buffer(/\r\n|\r|\n/g, eol);
                let str = chunks [i].buffer
                let newLineStart = LineStarts.createLineStartsArray(str)
                chunks[i] = StringBuffer(buffer: str, lineStarts: newLineStart)
            }
        }

        return PieceTreeTextBuffer(chunks: &chunks, BOM: bom, eol: eol, containsRTL: containsRtl, isBasicASCII: isBasicAscii, eolNormalized: normalizeEol)
    }


    public func getFirstLineText(lengthLimit: Int) -> V {
        return V (chunks [0].buffer [0..<lengthLimit])
        // TODO
        // return chunks[0].buffer.substr(0, 100).split(/\r\n|\r|\n/)[0];
    }
}

public class PieceTreeTextBufferBuilder<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Index == Int {
    var chunks: [StringBuffer<V>] = []
    var bom: V = V()
    
    var hasPreviousChar: Bool = false
    var previousChar: V.Element

    var cr: Int = 0
    var lf: Int = 0
    var crlf: Int = 0

    private init (previousChar: V.Element)
    {
        self.previousChar = previousChar
    }
}

extension PieceTreeTextBufferBuilder where V == [UInt8] {

    public convenience init() {
        self.init(previousChar: 0)
    }

    public func acceptChunk (_ str: String, encoding: String.Encoding = .utf8)
    {
        if let d = str.data (using: encoding){
            acceptChunk(V(d))
        }
    }
    
    public func acceptChunk(_ _chunk: V)
    {
        if _chunk.count == 0 {
            return
        }

        var chunk = _chunk
        if chunks.count == 0 {
            if startsWithUTF8BOM(chunk) {
                bom = V (bomArray)
                chunk = V (chunk [3...])
            }
        }
        
        let lastChar = chunk [chunk.count - 1]
        if (lastChar == 13) {
            // last character is \r
            acceptChunk1(V (chunk [0..<chunk.count - 1]), allowEmptyStrings: false)
            hasPreviousChar = true
            previousChar = lastChar
        } else {
            acceptChunk1(chunk, allowEmptyStrings: false)
            hasPreviousChar = false
            previousChar = lastChar
        }
    }

    func acceptChunk1(_ chunk: V, allowEmptyStrings: Bool) {
        if !allowEmptyStrings && chunk.count == 0 {
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
        let lineStarts = LineStarts(data: chunk)

        chunks.append (StringBuffer(buffer: chunk, lineStarts: lineStarts.lineStarts))
        cr += lineStarts.cr
        lf += lineStarts.lf
        crlf += lineStarts.crlf
    }

    public func finish(normalizeEol: Bool = true) -> PieceTreeTextBufferFactory<V> {
        finish()
        return PieceTreeTextBufferFactory(chunks: chunks, bom: bom, cr: cr, lf: lf, crlf: crlf, normalizeEol: normalizeEol)
    }

    func finish()
    {
        if chunks.count == 0 {
            acceptChunk1(V(), allowEmptyStrings: true)
        }

        if hasPreviousChar {
            hasPreviousChar = false
            // recreate last chunk
            let lastidx = chunks.count-1
            chunks[lastidx].buffer += [previousChar]
            let newLineStarts = LineStarts.createLineStartsArray(chunks [lastidx].buffer)
            chunks [lastidx].lineStarts = newLineStarts

            if (previousChar == 13) {
                cr += 1
            }
        }
    }
}
