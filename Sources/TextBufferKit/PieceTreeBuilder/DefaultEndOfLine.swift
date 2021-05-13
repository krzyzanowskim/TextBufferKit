//
//  PieceTreeBuilder.swift
//  swift-textbuffer
//
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

public enum DefaultEndOfLine<V: RangeReplaceableCollection & BidirectionalCollection & Hashable>: String {
    /**
     * Use line feed (\n) as the end of line character.
     */
    case LF = "\n"
    /**
     * Use carriage return and line feed (\r\n) as the end of line character.
     */
    case CRLF = "\r\n"

    // RawRepresentable stub

    var stringValue: String {
        rawValue
    }
}

extension DefaultEndOfLine where V == [UInt8] {
    public init?(rawValue: [UInt8]) {
        switch String(decoding: rawValue, as: UTF8.self) {
        case DefaultEndOfLine.CRLF.stringValue:
            self = .CRLF
        case DefaultEndOfLine.LF.stringValue:
            self = .LF
        default:
            return nil
        }
    }

    public var rawValue: [UInt8] {
        switch self {
        case .CRLF:
            return stringValue.unicodeScalars.map { UInt8($0.value) }
        case .LF:
            return stringValue.unicodeScalars.map { UInt8($0.value) }
        }
    }
}

extension DefaultEndOfLine where V == String {
    public init?(rawValue: String) {
        switch rawValue {
        case DefaultEndOfLine.CRLF.stringValue:
            self = .CRLF
        case DefaultEndOfLine.LF.stringValue:
            self = .LF
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .CRLF:
            return stringValue
        case .LF:
            return stringValue
        }
    }
}
