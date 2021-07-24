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

extension PieceTreeBase where V == String {
    /// Initializes the PieceTreeBase
    /// - Parameter eol: must be a String either "\n" or "\r\n"
    ///
    public convenience init (chunks: inout [StringBuffer<V>], eol: V = "\n", eolNormalized: Bool)
    {
        self.init(eol: eol)
        create(chunks: &chunks, eol: eol, eolNormalized: eolNormalized)
    }

    public var eol: V {
        get {
            return _eol
        }
        set {
            _eol = newValue
            normalizeEol()
        }
    }

    func create (chunks: inout [StringBuffer<V>], eol: V, eolNormalized: Bool)
    {
        let buffer = V()
        self.buffers = [StringBuffer<V>(buffer: buffer, lineStarts: [buffer.startIndex])]
        self.lineCount = 1
        self.length = 0
        self._eol = eol
        self.eolNormalized = eolNormalized

        var lastNode: TreeNode? = nil
        var i = 0
        let top = chunks.count
        while i < top {
            if chunks[i].buffer.count > 0 {
                if chunks[i].lineStarts.count == 0 {
                    chunks[i].lineStarts = createLineStartsArray (chunks[i].buffer)
                }

                let lastLineIndex = chunks[i].lineStarts.count - 1
                let lastLineStartIndex = chunks[i].lineStarts[lastLineIndex]
                let endColumnIndex = chunks[i].buffer.distance(from: chunks[i].buffer.startIndex, to: lastLineStartIndex)

                let piece = Piece(
                    bufferIndex: i + 1,
                    start: BufferCursor(line: 0, column: 0),
                    end: BufferCursor(line: lastLineIndex, column: endColumnIndex),
                    length: chunks[i].buffer.count,
                    lineFeedCount: chunks[i].lineStarts.count - 1
                )

                // let piece = Piece(bufferIndex: i+1,
                //                   start: BufferCursor(line: 0, column: 0),
                //                   end: BufferCursor(line: chunks[i].lineStarts.count - 1, column: chunks[i].buffer.count - chunks[i].lineStarts[chunks[i].lineStarts.count - 1]),
                //                   length: chunks[i].buffer.count, lineFeedCount: chunks[i].lineStarts.count - 1)

                buffers.append (chunks[i]);
                lastNode = rbInsertRight (lastNode, piece)
            }
            i += 1
        }
        searchCache = PieceTreeSearchCache(limit: 1)
        lastVisitedLine = (0, V())
        computeBufferMetadata()
    }

    // Replaces \r\n, \r and \n with the value of eol
    private func replaceNewLines (_ val: V) -> V
    {
        let result = val.map { v -> V.Element in
            switch v {
            case "\r\n", "\n", "\r":
                return Character(_eol)
            default:
                return v
            }
        }

        return V(result)
    }


    private func normalizeEol ()
    {
        let averageBufferSize = self.averageBufferSize
        let min = Int (Float (averageBufferSize) - floor(Float (averageBufferSize / 3)))
        let max = min * 2

        var tempChunk: V = V()
        var tempChunkLen = 0
        var chunks: [StringBuffer<V>] = [StringBuffer<V>]()

        iterate(node: root, callback: { node in
            let str = getNodeContent(node)
            let len = str.count
            if (tempChunkLen <= min || tempChunkLen + len < max) {
                tempChunk += str
                tempChunkLen += len
                return true
            }

            // flush anyways
            let text = replaceNewLines (tempChunk)
            chunks.append(StringBuffer(buffer: text, lineStarts: createLineStartsArray(text)))
            tempChunk = str
            tempChunkLen = len
            return true
        })

        if (tempChunkLen > 0) {
            let text = replaceNewLines (tempChunk)
            chunks.append (StringBuffer(buffer: text, lineStarts: createLineStartsArray(text)))
        }

        create(chunks: &chunks, eol: _eol, eolNormalized: true)
    }

    /// Splits a buffer containing the whole text in lines,
    /// where lines are those with \r\n, \r or \n
    static func splitBufferInLines (_ contents: V) -> [V]
    {
        guard !contents.isEmpty else {
            return []
        }

        var result: [V] = [V()]
        var line = V()
        for c in contents {
            switch c {
            case "\r\n", "\n", "\r":
                result.append(line)
                line = V()
            default:
                line.append(c)
            }
        }

        if !line.isEmpty {
            result.append(line)
        }

        return result
    }

    public func getPositionAt(_ _offset: Int) -> Position {
        var offset = max (0, _offset)

        var x = root
        var lfCount = 0;
        let originalOffset = offset

        while x !== TreeNode.SENTINEL {
            if x.size_left != 0 && x.size_left >= offset {
                x = x.left!
            } else if x.size_left + x.piece.length >= offset {
                let out = getIndexOf(node: x, accumulatedValue: offset - x.size_left)

                lfCount += x.lf_left + out.index

                if out.index == 0 {
                    let lineStartOffset = getOffsetAt(lfCount + 1, 1)
                    let column = originalOffset - lineStartOffset
                    return Position(line: lfCount+1, column: column+1)
                }

                return Position(line: lfCount + 1, column: out.remainder + 1)
            } else {
                offset -= x.size_left + x.piece.length;
                lfCount += x.lf_left + x.piece.lineFeedCount

                if x.right === TreeNode.SENTINEL {
                    // last node
                    let lineStartOffset = getOffsetAt(lfCount + 1, 1);
                    let column = originalOffset - offset - lineStartOffset;
                    return Position(line: lfCount + 1, column: column + 1);
                } else {
                    x = x.right!
                }
            }
        }

        return Position(line: 1, column: 1)
    }

    func getIndexOf(node: TreeNode, accumulatedValue: Int) -> (index: Int, remainder: Int ) {
        let piece = node.piece
        let pos = positionInBuffer(node: node, remainder: accumulatedValue)
        let lineCnt = pos.line - piece.start.line
        let stringBuffer = buffers[piece.bufferIndex]
        let distance = stringBuffer.buffer.distance(from: offsetInBuffer(piece.bufferIndex, piece.start), to: offsetInBuffer(piece.bufferIndex, piece.end))

        if distance == accumulatedValue {
            // we are checking the end of this node, so a CRLF check is necessary.
            let realLineCnt = getLineFeedCount(bufferIndex: node.piece.bufferIndex, start: piece.start, end: pos)
            if realLineCnt != lineCnt {
                // aha yes, CRLF
                return (index: realLineCnt, remainder: 0)
            }
        }
        return (index: lineCnt, remainder: pos.column)
    }


    func positionInBuffer(node: TreeNode, remainder: Int) -> BufferCursor {
        let piece = node.piece
        let bufferIndex = node.piece.bufferIndex
        let lineStarts = buffers[bufferIndex].lineStarts
        let stringBuffer = buffers[bufferIndex]

        let startOffset = stringBuffer.buffer.index(lineStarts[piece.start.line], offsetBy: piece.start.column)

        let offset = stringBuffer.buffer.index(startOffset, offsetBy: remainder)

        // binary search offset between startOffset and endOffset
        var low = piece.start.line
        var high = piece.end.line

        var mid = 0
        var midStop = stringBuffer.buffer.startIndex
        var midStart = stringBuffer.buffer.startIndex

        while low <= high {
            mid = low + ((high - low) / 2) | 0
            midStart = lineStarts[mid]

            if mid == high {
                break
            }

            midStop = lineStarts[mid + 1]

            if offset < midStart {
                high = mid - 1
            } else if offset >= midStop {
                low = mid + 1
            } else {
                break
            }
        }

        return BufferCursor(line: mid, column: stringBuffer.buffer.distance(from: midStart, to: offset))// offset - midStart)
    }

    func getLineFeedCount(bufferIndex: Int, start: BufferCursor, end: BufferCursor) -> Int
    {
        // we don't need to worry about start: abc\r|\n, or abc|\r, or abc|\n, or abc|\r\n doesn't change the fact that, there is one line break after start.
        // now let's take care of end: abc\r|\n, if end is in between \r and \n, we need to add line feed count by 1
        if end.column == 0 {
            return end.line - start.line
        }

        let lineStarts = buffers[bufferIndex].lineStarts
        if end.line == lineStarts.count - 1 { // it means, there is no \n after end, otherwise, there will be one more lineStart.
            return end.line - start.line
        }

        let buffer = buffers[bufferIndex].buffer
        let nextLineStartOffset = lineStarts[end.line + 1]

        let endOffset = buffer.index(lineStarts[end.line], offsetBy: end.column)
        if nextLineStartOffset > buffer.index(after: endOffset) { // there are more than 1 character after end, which means it can't be \n
            return end.line - start.line
        }
        // endOffset + 1 === nextLineStartOffset
        // character at endOffset is \n, so we check the character before first
        // if character at endOffset is \r, end.column is 0 and we can't get here.
        let previousCharOffset = buffer.index(before: endOffset) // end.column > 0 so it's okay.

        if buffer [previousCharOffset] == Character("\r") {
            return end.line - start.line + 1
        } else {
            return end.line - start.line
        }
    }
}

