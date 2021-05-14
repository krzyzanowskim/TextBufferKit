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

/**
 * Tracks the offset for each start of a line created from a byte array
 */
struct LineStarts<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> {

    /// Offsets for each line start
    public var lineStarts: [Int]
    /// Number of carriage returns found
    public var cr: Int
    /// Number of line feeds found
    public var lf: Int
    /// Number of carriage returns followed by line feeds found
    public var crlf: Int
    /// Whether this file contains simple ascii characters (tab, and chars 32 to 127) or not
    public var isBasicAscii: Bool

}

extension LineStarts where V == [UInt8] {
    /**
     * Given a byte array containing the text buffer, create an array pointing to the
     * beginning of each line -- where lines are considered those immediately after a
     * \r\n or a \n
     */
    static func createLineStartsArray (_ data: V) -> [Int]
    {
        var result: [Int] = [0]
        var i = 0
        let len = data.count
        while i < data.count {
            let chr = data [i]
            if chr == 13 { // \r
                if (i+1) < len && data [i+1] == 10 { // \n
                    // \r\n case
                    result.append (i + 2)
                    i += 1 // skip \n
                } else {
                    // \r .. case
                    result.append (i + 1)
                }
            } else if chr == 10 { // \n
                result.append (i + 1)
            }
            i += 1
        }
        return result
    }

    /**
     * Creates a LineStarts structure from the given byte array
     */
    init (data: V)
    {
        var result: [Int] = [0]
        var cr = 0
        var lf = 0
        var crlf = 0
        var isBasicAscii = true

        var i = 0
        let len = data.count
        while i < data.count {
            let chr = data [i]
            if chr == 13 {
                if (i+1) < len && data [i+1] == 10 {
                    // \r\n case
                    crlf += 1
                    result.append (i + 2)
                    i += 1 // skip \n
                } else {
                    cr += 1
                    // \r .. case
                    result.append (i + 1)
                }
            } else if chr == 10 {
                lf += 1
                result.append(i+1)
            } else {
                if isBasicAscii {
                    if chr != 8 && (chr < 32 || chr > 126) {
                        isBasicAscii = false
                    }
                }
            }
            i += 1
        }
        lineStarts = result
        self.cr = cr
        self.lf = lf
        self.crlf = crlf
        self.isBasicAscii = isBasicAscii
    }

}
