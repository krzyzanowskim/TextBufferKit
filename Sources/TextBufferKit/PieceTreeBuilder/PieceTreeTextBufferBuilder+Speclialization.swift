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

extension PieceTreeTextBufferBuilder where V == String {

    public convenience init()
    {
        self.init(
            previousChar: Character(""),
            newLine: "\n",
            lineFeed: "\r",
            // The character \u{feff} is the BOM character for all UTFs (8, 16 LE and 16 BE).
            bomIndicator: "\u{feff}"
        )
    }
}

extension PieceTreeTextBufferBuilder where V == [UInt8] {

    public convenience init()
    {
        self.init(
            previousChar: 0,
            newLine: 10,
            lineFeed: 13,
            // UTF8-BOM 0xEF,0xBB,0xBF
            bomIndicator: [0xeb, 0xbb, 0xbf]
        )
    }
}
