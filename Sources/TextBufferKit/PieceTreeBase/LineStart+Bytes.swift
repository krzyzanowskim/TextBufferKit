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

extension LineStarts where V == [UInt8] {
    /**
     * Creates a LineStarts structure from the given byte array
     */
    init (data: V)
    {
        let newLine: V.Element = 10
        let lineFeed: V.Element = 13
        var result  = [data.startIndex]
        var cr = 0
        var lf = 0
        var crlf = 0

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
    }
}

/**
 * Given a byte array containing the text buffer, create an array pointing to the
 * beginning of each line -- where lines are considered those immediately after a
 * \r\n or a \n
 */
func createLineStartsArray(_ data: [UInt8]) -> [Int]
{
    var result = [data.startIndex]
    let newLine: UInt8 = 10
    let lineFeed: UInt8 = 13

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
