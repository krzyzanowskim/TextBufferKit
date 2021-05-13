//
//  PieceTreeBuilder.swift
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

public class IdentifiedSingleEditOperation<V: RangeReplaceableCollection & RandomAccessCollection & Hashable> where V.Index == Int, V.Element == UInt8 {
    /// An identifier associated with this single edit operation.
    public var identifier: SingleEditOperationIdentifier?
    /// The range to replace. This can be empty to emulate a simple insert.
    public var range: Range<V>
    /// The text to replace with. This can be null to emulate a simple delete.
    public var text: V?
    /// This indicates that this operation has "insert" semantics.
    /// This indicates that this operation has "insert" semantics.
    public var forceMoveMarkers: Bool
    /// This indicates that this operation is inserting automatic whitespace
    /// that can be removed on next model edit operation if `config.trimAutoWhitespace` is true.
    public var isAutoWhitespaceEdit: Bool?
    /// This indicates that this operation is in a set of operations that are tracked and should not be "simplified".
    var isTracked: Bool

    internal init(identifier: SingleEditOperationIdentifier?, range: Range<V>, text: V?, forceMoveMarkers: Bool, isAutoWhitespaceEdit: Bool?, isTracked: Bool) {
        self.identifier = identifier
        self.range = range
        self.text = text
        self.forceMoveMarkers = forceMoveMarkers
        self.isAutoWhitespaceEdit = isAutoWhitespaceEdit
        self.isTracked = isTracked
    }
}
