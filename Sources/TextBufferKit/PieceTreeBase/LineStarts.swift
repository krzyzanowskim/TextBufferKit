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
struct LineStarts<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Element: Equatable {
    /// Offsets for each line start
    public var lineStarts: [V.Index] = []
    /// Number of carriage returns found
    public var cr: Int = 0
    /// Number of line feeds found
    public var lf: Int = 0
    /// Number of carriage returns followed by line feeds found
    public var crlf: Int = 0
    /// Whether this file contains simple ascii characters (tab, and chars 32 to 127) or not
    // TODO
    // public var isBasicAscii: Bool = true

    private let lineFeed: V.Element
    private let newLine: V.Element

    /**
     * Creates a LineStarts structure from the given byte array
     */
    init (data: V, newLine: V.Element, lineFeed: V.Element)
    {
        var result  = [data.startIndex]
        var cr = 0
        var lf = 0
        var crlf = 0
        // var isBasicAscii = true

        for var i in data.indices {
            let chr = data[i]
            if chr == lineFeed {
                if data.index(after: i) < data.endIndex && data[data.index(after: i)] == newLine {
                    // \r\n case
                    crlf += 1
                    result.append(data.index(after: i))
                    i = data.index(after: i) // skip \n
                } else {
                    cr += 1
                    // \r .. case
                    result.append(data.index(after: i))
                }
            } else if chr == newLine {
                lf += 1
                result.append(data.index(after:i))
            // } else if isBasicAscii {
            //    isBasicAscii = isBasicAsciiElement(chr)
            }
        }

        lineStarts = result
        self.cr = cr
        self.lf = lf
        self.crlf = crlf
        self.newLine = newLine
        self.lineFeed = lineFeed
        // self.isBasicAscii = isBasicAscii
    }

    /**
     * Given a byte array containing the text buffer, create an array pointing to the
     * beginning of each line -- where lines are considered those immediately after a
     * \r\n or a \n
     */
    static func createLineStartsArray (_ data: V, newLine: V.Element, lineFeed: V.Element) -> [V.Index] {
        var result = [data.startIndex]
        for var i in data.indices {
            let chr = data[i]
            if chr == lineFeed { // \r
                if data.index(after: i) < data.endIndex && data[data.index(after: i)] == newLine {
                    // \r\n case
                    result.append(data.index(i, offsetBy: 2)) // skip \n
                    i = data.index(after:i)
                } else {
                    // \r .. case
                    result.append(data.index(after: i))
                }
            } else if chr == newLine { // \n
                result.append (data.index(after: i))
            }
        }

        return result
    }
}
