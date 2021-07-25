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

    public static func equal (left: PieceTreeBase, right: PieceTreeBase) -> Bool
    {
        if left.length != right.length {
            return false
        }
        if left.lineCount != right.lineCount {
            return false
        }

        let ret = left.iterate(node: left.root, callback: { node in
            if node === TreeNode.SENTINEL {
                return true
            }
            let str = left.getNodeContent(node)
            let len = str.count
            if let startPosition = right.nodeAt(0) {
                if let endPosition = right.nodeAt(len) {
                    let val = right.getValueInRange2(startPosition, endPosition);

                    return str == val
                }
            }
            return false
        })

        return ret;
    }

    func nodeAt(_ _offset: Int) -> NodePosition?
    {
        var offset = _offset
        var x = root
        if let cache = searchCache.get(offset: offset) {
            return NodePosition (node: cache.node, remainder: offset - cache.nodeStartOffset, nodeStartOffset: cache.nodeStartOffset)
        }

        var nodeStartOffset = 0

        while x !== TreeNode.SENTINEL {
            if x.size_left > offset {
                x = x.left!
            } else if x.size_left + x.piece.length >= offset {
                nodeStartOffset += x.size_left
                let ret = NodePosition(node: x, remainder: offset - x.size_left, nodeStartOffset: nodeStartOffset)
                searchCache.set(CacheEntry (ret))
                return ret
            } else {
                offset -= x.size_left + x.piece.length
                nodeStartOffset += x.size_left + x.piece.length
                x = x.right!
            }
        }

        return nil
    }

    func getValueInRange2(_ startPosition: NodePosition, _ endPosition: NodePosition) -> V {
        if startPosition.node === endPosition.node {
            let node = startPosition.node
            let buffer = buffers[node.piece.bufferIndex].buffer
            let startOffset = offsetInBuffer(node.piece.bufferIndex, node.piece.start)
            return V (buffer [buffer.index(startOffset, offsetBy: startPosition.remainder)..<buffer.index(startOffset, offsetBy: endPosition.remainder)])
        }

        var x = startPosition.node
        var buffer = buffers[x.piece.bufferIndex].buffer
        let startOffset = offsetInBuffer(x.piece.bufferIndex, x.piece.start)
        var ret = V (buffer [buffer.index(startOffset, offsetBy: startPosition.remainder)..<buffer.index(startOffset, offsetBy: x.piece.length)])

        x = x.next()
        while x !== TreeNode.SENTINEL {
            buffer = buffers [x.piece.bufferIndex].buffer
            let startOffset = offsetInBuffer(x.piece.bufferIndex, x.piece.start)

            if x === endPosition.node {
                ret += Array (buffer [startOffset..<buffer.index(startOffset, offsetBy: endPosition.remainder)])
                break;
            } else {
                ret += Array (buffer[startOffset..<buffer.index(startOffset, offsetBy: x.piece.length)])
            }

            x = x.next()
        }

        return ret
    }

    public func createSnapshot(bom: V) -> PieceTreeSnapshot<V> {
        return PieceTreeSnapshot(tree: self, bom: bom);
    }

    func delete(offset: Int, cnt: Int)
    {
        lastVisitedLine.lineNumber = 0
        lastVisitedLine.value = V()

        if cnt <= 0 || root === TreeNode.SENTINEL {
            return
        }

        guard let startPosition = nodeAt(offset) else {
            return
        }
        guard let endPosition = nodeAt(offset + cnt) else {
            return
        }
        var startNode = startPosition.node
        var endNode = endPosition.node

        if startNode === endNode {
            let startSplitPosInBuffer = positionInBuffer(node: startNode, remainder: startPosition.remainder)
            let endSplitPosInBuffer = positionInBuffer(node: startNode, remainder: endPosition.remainder)

            if startPosition.nodeStartOffset == offset {
                if cnt == startNode.piece.length { // delete node
                    var next = startNode.next()
                    rbDelete(self, startNode)
                    validateCRLFWithPrevNode(nextNode: &next)
                    computeBufferMetadata()
                    return
                }
                deleteNodeHead(node: &startNode, pos: endSplitPosInBuffer)
                searchCache.validate(offset: offset)
                validateCRLFWithPrevNode(nextNode: &startNode)
                computeBufferMetadata()
                return
            }

            if startPosition.nodeStartOffset + startNode.piece.length == offset + cnt {
                deleteNodeTail(node: &startNode, pos: startSplitPosInBuffer)
                validateCRLFWithNextNode(node: &startNode)
                computeBufferMetadata();
                return;
            }

            // delete content in the middle, this node will be splitted to nodes
            shrinkNode(node: &startNode, start: startSplitPosInBuffer, end: endSplitPosInBuffer);
            computeBufferMetadata();
            return;
        }

        var nodesToDel: [TreeNode] = []

        let startSplitPosInBuffer = positionInBuffer(node: startNode, remainder: startPosition.remainder)
        deleteNodeTail(node: &startNode, pos: startSplitPosInBuffer)
        searchCache.validate(offset: offset)
        if (startNode.piece.length == 0) {
            nodesToDel.append(startNode)
        }

        // update last touched node
        let endSplitPosInBuffer = positionInBuffer(node: endNode, remainder: endPosition.remainder)
        deleteNodeHead(node: &endNode, pos: endSplitPosInBuffer);
        if endNode.piece.length == 0 {
            nodesToDel.append(endNode);
        }

        // delete nodes in between
        let secondNode = startNode.next()
        var node = secondNode
        while node !== TreeNode.SENTINEL && node !== endNode {
            nodesToDel.append(node)
            node = node.next()
        }

        var prev = startNode.piece.length == 0 ? startNode.prev() : startNode
        deleteNodes(nodesToDel)
        validateCRLFWithNextNode(node: &prev)
        computeBufferMetadata()
    }

    func validateCRLFWithPrevNode(nextNode: inout TreeNode)
    {
        if shouldCheckCRLF() && startWithLF(nextNode) {
            var node = nextNode.prev()
            if endWithCR(node) {
                fixCRLF(prev: &node, next: &nextNode)
            }
        }
    }

    func validateCRLFWithNextNode(node: inout TreeNode)
    {
        if shouldCheckCRLF() && endWithCR(node) {
            var nextNode = node.next()
            if startWithLF(nextNode) {
                fixCRLF(prev: &node, next: &nextNode)
            }
        }
    }

    private func fixCRLF(prev: inout TreeNode, next: inout TreeNode)
    {
        var nodesToDel: [TreeNode] = []
        // update node
        let prevPiecStringeBuffer = buffers[prev.piece.bufferIndex]
        let lineStarts = prevPiecStringeBuffer.lineStarts
        let newEnd: BufferCursor


        if prev.piece.end.column == 0 {
            // it means, last line ends with \r, not \r\n
            newEnd = BufferCursor (
                line: prev.piece.end.line - 1,
                column: prevPiecStringeBuffer.buffer.distance(from: lineStarts[prev.piece.end.line - 1], to: lineStarts[prev.piece.end.line]) - 1 //lineStarts[prev.piece.end.line] - lineStarts[prev.piece.end.line - 1] - 1
            )
        } else {
            // \r\n
            newEnd = BufferCursor (line: prev.piece.end.line, column: prev.piece.end.column - 1)
        }

        let prevNewLength = prev.piece.length - 1
        let prevNewLFCnt = prev.piece.lineFeedCount - 1
        prev.piece = Piece(bufferIndex: prev.piece.bufferIndex, start: prev.piece.start, end: newEnd, length: prevNewLength, lineFeedCount: prevNewLFCnt)

        updateTreeMetadata(self, prev, -1, -1);
        if (prev.piece.length == 0) {
            nodesToDel.append(prev)
        }

        // update nextNode
        let newStart = BufferCursor (line: next.piece.start.line + 1, column: 0)
        let newLength = next.piece.length - 1
        let newLineFeedCnt = getLineFeedCount(bufferIndex: next.piece.bufferIndex, start: newStart, end: next.piece.end)
        next.piece = Piece(bufferIndex: next.piece.bufferIndex, start: newStart, end: next.piece.end, length: newLength, lineFeedCount: newLineFeedCnt)

        updateTreeMetadata(self, next, -1, -1)
        if (next.piece.length == 0) {
            nodesToDel.append(next)
        }

        // create new piece which contains \r\n
        let pieces = createNewPieces("\r\n")
        let _ = rbInsertRight(prev, pieces[0])
        // delete empty nodes

        for node in nodesToDel {
            rbDelete(self, node)
        }
    }

    func adjustCarriageReturnFromNext(value: inout V, node: TreeNode) -> Bool {
        if shouldCheckCRLF() && endWithCR(value) {
            let nextNode = node.next()
            if startWithLF(nextNode) {
                // move `\n` forward
                value += ["\n"]

                if nextNode.piece.length == 1 {
                    rbDelete(self, nextNode)
                } else {
                    let piece = nextNode.piece
                    let newStart: BufferCursor = BufferCursor(line: piece.start.line + 1, column: 0)
                    let newLength = piece.length - 1
                    let newLineFeedCount = getLineFeedCount(bufferIndex: piece.bufferIndex, start: newStart, end: piece.end)
                    nextNode.piece = Piece(bufferIndex: piece.bufferIndex, start: newStart, end: piece.end, length: newLength, lineFeedCount: newLineFeedCount)
                    updateTreeMetadata(self, nextNode, -1, -1)
                }
                return true
            }
        }

        return false
    }

    func shouldCheckCRLF() -> Bool {
        !(eolNormalized && eol == "\n");
    }

    func startWithLF(_ val: V) -> Bool
    {
        val.hasPrefix("\n")
    }

    func startWithLF(_ val: TreeNode) -> Bool
    {
        if val === TreeNode.SENTINEL || val.piece.lineFeedCount == 0 {
            return false
        }

        let piece = val.piece
        let lineStarts = buffers[piece.bufferIndex].lineStarts
        let stringBuffer = buffers[piece.bufferIndex]
        let line = piece.start.line
        let startOffset = stringBuffer.buffer.index(lineStarts[line], offsetBy: piece.start.column)
        if line == (lineStarts.count - 1) {
            // last line, so there is no line feed at the end of this line
            return false
        }
        let nextLineOffset = lineStarts[line + 1]
        if nextLineOffset > stringBuffer.buffer.index(after:startOffset) {
            return false
        }
        return buffers[piece.bufferIndex].buffer [startOffset] == "\n"
    }

    func endWithCR(_ val: V) -> Bool {
        val.last == "\r"
    }

    func endWithCR(_ val: TreeNode) -> Bool {
        if val === TreeNode.SENTINEL || val.piece.lineFeedCount == 0 {
            return false
        }

        return nodeCharCodeAt(val, val.piece.length - 1) == "\r"
    }

    func deleteNodeTail(node: inout TreeNode, pos: BufferCursor)
    {
        let piece = node.piece
        let originalLFCnt = piece.lineFeedCount
        let originalEndOffset = offsetInBuffer(piece.bufferIndex, piece.end)
        let stringBuffer = buffers[piece.bufferIndex]

        let newEnd = pos
        let newEndOffset = offsetInBuffer(piece.bufferIndex, newEnd)
        let newLineFeedCnt = getLineFeedCount(bufferIndex: piece.bufferIndex, start: piece.start, end: newEnd)

        let lf_delta = newLineFeedCnt - originalLFCnt
        let size_delta = stringBuffer.buffer.distance(from: originalEndOffset, to: newEndOffset)
        let newLength = piece.length + size_delta

        node.piece = Piece(bufferIndex: piece.bufferIndex, start: piece.start, end: newEnd, length: newLength, lineFeedCount: newLineFeedCnt)

        updateTreeMetadata(self, node, size_delta, lf_delta)
    }

    func deleteNodeHead(node: inout TreeNode, pos: BufferCursor)
    {
        let piece = node.piece
        let originalLFCnt = piece.lineFeedCount
        let originalStartOffset = offsetInBuffer(piece.bufferIndex, piece.start)
        let stringBuffer = buffers[piece.bufferIndex]

        let newStart = pos
        let newLineFeedCnt = getLineFeedCount(bufferIndex: piece.bufferIndex, start: newStart, end: piece.end)
        let newStartOffset = offsetInBuffer(piece.bufferIndex, newStart)
        let lf_delta = newLineFeedCnt - originalLFCnt
        let size_delta = stringBuffer.buffer.distance(from: originalStartOffset, to: newStartOffset)
        let newLength = piece.length + size_delta
        node.piece = Piece(bufferIndex: piece.bufferIndex, start: newStart, end: piece.end, length: newLength, lineFeedCount: newLineFeedCnt)

        updateTreeMetadata(self, node, size_delta, lf_delta);
    }

    private func shrinkNode(node: inout TreeNode, start: BufferCursor, end: BufferCursor)
    {
        let piece = node.piece
        let originalStartPos = piece.start
        let originalEndPos = piece.end

        // old piece, originalStartPos, start
        let oldLength = piece.length
        let oldLFCnt = piece.lineFeedCount
        let newEnd = start
        let newLineFeedCnt = getLineFeedCount(bufferIndex: piece.bufferIndex, start: piece.start, end: newEnd)

        let newLength = buffers[piece.bufferIndex].buffer.distance(from: offsetInBuffer(piece.bufferIndex, originalStartPos), to: offsetInBuffer(piece.bufferIndex, start)) // start - originalStartPos

        node.piece = Piece(bufferIndex: piece.bufferIndex, start: piece.start, end: newEnd, length: newLength, lineFeedCount: newLineFeedCnt)

        updateTreeMetadata(self, node, newLength - oldLength, newLineFeedCnt - oldLFCnt)

        // new right piece, end, originalEndPos
        let pieceBuffer = buffers[piece.bufferIndex].buffer
        let newPiece = Piece(
            bufferIndex: piece.bufferIndex,
            start: end,
            end: originalEndPos,
            length: pieceBuffer.distance(from: offsetInBuffer(piece.bufferIndex, end), to: offsetInBuffer(piece.bufferIndex, originalEndPos)), //offsetInBuffer(piece.bufferIndex, originalEndPos) - offsetInBuffer(piece.bufferIndex, end),
            lineFeedCount: getLineFeedCount(bufferIndex: piece.bufferIndex, start: end, end: originalEndPos)
        )

        var newNode = rbInsertRight(node, newPiece)
        validateCRLFWithPrevNode(nextNode: &newNode)
    }

    func createNewPieces(_ _text: V) -> [Piece]
    {
        var text = _text

        if text.count > averageBufferSize {
            // the content is large, operations like subString, charCode becomes slow
            // so here we split it into smaller chunks, just like what we did for CR/LF normalization
            var newPieces: [Piece] = []
            newPieces.reserveCapacity(averageBufferSize)
            while text.count > averageBufferSize {
                let startIndex = text.startIndex
                let lastCharIndex = text.index(startIndex, offsetBy: averageBufferSize - 1)
                let lastChar = text [lastCharIndex]
                var splitText: V

                // TODO: This code has some half-cooked code that does Unicode here
                if lastChar == "\r" || (lastChar.unicodeScalars.first!.value >= 0xD800 && lastChar.unicodeScalars.first!.value <= 0xDBFF) {
                    // last character is \r or a high surrogate => keep it back
                    splitText = V (text [startIndex..<lastCharIndex])
                    text = V(text [lastCharIndex...])
                } else {
                    let lastCharIndex = text.index(startIndex, offsetBy: averageBufferSize)
                    splitText = V (text [startIndex..<lastCharIndex])
                    text = V(text[lastCharIndex...])
                }

                let lineStarts = createLineStartsArray(V (splitText))
                newPieces.append(
                    Piece(
                        bufferIndex: buffers.count,
                        start: BufferCursor(
                            line: 0,
                            column: 0
                        ),
                        end: BufferCursor(
                            line: lineStarts.count - 1,
                            column: splitText.distance(from: lineStarts.last!, to: splitText.indices.last!) //splitText.count - lineStarts[lineStarts.count-1]
                        ),
                        length: splitText.count, lineFeedCount: lineStarts.count-1
                    )
                )
                buffers.append(StringBuffer(buffer: splitText, lineStarts: lineStarts));
            }

            let lineStarts = createLineStartsArray (V(text))
            newPieces.append(
                Piece(
                    bufferIndex: buffers.count,
                    start: BufferCursor(line: 0, column: 0),
                    end: BufferCursor(line: lineStarts.count - 1, column: text.distance(from: lineStarts.last!, to: text.indices.last!)), //text.count - lineStarts[lineStarts.count-1]),
                    length: text.count, lineFeedCount: lineStarts.count - 1
                )
            )
            buffers.append(StringBuffer(buffer: V (text), lineStarts: lineStarts))

            return newPieces
        }

        var startOffset = buffers[0].buffer.indices.last!
        var lineStarts = createLineStartsArray(_text)

        var start = lastChangeBufferPos

        // co to jest, startOffset to endIndex? czy nie
        if startOffset != buffers[0].buffer.startIndex,
           buffers[0].lineStarts[buffers[0].lineStarts.count - 1] == startOffset,
           startWithLF(_text),
           endWithCR(buffers[0].buffer) // todo, we can check _lastChangeBufferPos's column as it's the last one
        {
            lastChangeBufferPos = BufferCursor(line: lastChangeBufferPos.line, column: lastChangeBufferPos.column + 1)
            start = lastChangeBufferPos

            for i in 0..<lineStarts.count {
                let distance = _text.distance(from: lineStarts[i], to: startOffset) + 1
                lineStarts[i] = _text.index(lineStarts[i], offsetBy: distance) //lineStarts[i] = lineStarts[i] + startOffset + 1
            }

            buffers[0].lineStarts = buffers[0].lineStarts + lineStarts [1...]
            buffers[0].buffer += [Character("_") /* 95 */] + _text
            startOffset = _text.index(after: startOffset) //startOffset += 1
        } else {
            if startOffset != buffers[0].buffer.startIndex {
                for i in 0..<lineStarts.count {
                    let distance = _text.distance(from: lineStarts[i], to: startOffset)
                    lineStarts[i] = _text.index(lineStarts[i], offsetBy: distance)
                }
            }
            buffers[0].lineStarts = buffers[0].lineStarts + lineStarts [1...]
            buffers[0].buffer += _text
        }

        let endOffset = buffers[0].buffer.indices.last!
        let endIndex = buffers[0].lineStarts.count - 1
        let endColumn = buffers[0].buffer.distance(from: buffers[0].lineStarts[endIndex], to: endOffset) // endOffset - buffers[0].lineStarts[endIndex]
        let endPos = BufferCursor (line: endIndex, column: endColumn)
        let newPiece = Piece(
            bufferIndex: 0,
            start: start,
            end: endPos,
            length: buffers[0].buffer.distance(from: startOffset, to: endOffset), //endOffset - startOffset,
            lineFeedCount: getLineFeedCount(bufferIndex: 0, start: start, end: endPos)
        )
        lastChangeBufferPos = endPos
        return [newPiece]
    }
}

