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

public enum EndOfLine<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> {
    /**
     * Use line feed (\n) as the end of line character.
     */
    case LF
    /**
     * Use carriage return and line feed (\r\n) as the end of line character.
     */
    case CRLF

    case CR

    fileprivate var stringValue: String {
        switch self {
        case .LF:
            return "\n"
        case .CR:
            return "\r"
        case .CRLF:
            return "\r\n"
        }
    }

    // It's a coincidence this is true for unicode and string, but not necessarily for everything else.
    var length: Int {
        switch self {
        case .LF, .CR:
            return 1
        case .CRLF:
            return 2
        }
    }
}

extension EndOfLine where V == [UInt8] {
    public init?(rawValue: [UInt8]) {
        switch String(decoding: rawValue, as: UTF8.self) {
        case EndOfLine.CRLF.stringValue:
            self = .CRLF
        case EndOfLine.LF.stringValue:
            self = .LF
        case EndOfLine.CR.stringValue:
            self = .CR
        default:
            return nil
        }
    }

    public var rawValue: V {
        switch self {
        case .CRLF:
            return stringValue.unicodeScalars.map { UInt8($0.value) }
        case .LF:
            return stringValue.unicodeScalars.map { UInt8($0.value) }
        case .CR:
            return stringValue.unicodeScalars.map { UInt8($0.value) }
        }
    }
}

extension EndOfLine where V == String {
    public init?(rawValue: V) {
        switch rawValue {
        case EndOfLine.CRLF.stringValue:
            self = .CRLF
        case EndOfLine.LF.stringValue:
            self = .LF
        case EndOfLine.CR.stringValue:
            self = .CR
        default:
            return nil
        }
    }

    public var rawValue: V {
        switch self {
        case .CRLF:
            return stringValue
        case .LF:
            return stringValue
        case .CR:
            return stringValue
        }
    }
}

