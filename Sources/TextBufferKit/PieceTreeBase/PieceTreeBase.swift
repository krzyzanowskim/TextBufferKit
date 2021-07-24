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

public class PieceTreeBase<V: RangeReplaceableCollection & BidirectionalCollection & Hashable> where V.Element: Equatable {
    var root: TreeNode = TreeNode.SENTINEL
    var buffers = [StringBuffer<V> (buffer: V(), lineStarts: [])]
    public internal(set) var lineCount: Int = 1
    public internal(set) var length: Int = 0
    
    /// This configuration variable can be used to control how small or large data is chunked in, the default is 64k
    public var averageBufferSize: Int = 64*1024 {
        didSet {
            if averageBufferSize < 1 {
                averageBufferSize = 64*1024
            }
        }
    }
    
    var _eol: V

    var eolLength: Int = 1
    var eolNormalized: Bool = true
    var lastChangeBufferPos: BufferCursor = BufferCursor(line: 0, column: 0)
    var searchCache: PieceTreeSearchCache = PieceTreeSearchCache(limit: 1)
    var lastVisitedLine: (lineNumber: Int, value: V) = (0, V())

    init(eol: V) {
        _eol = eol
    }

    @discardableResult
    func iterate(node: TreeNode, callback: (_ node: TreeNode) -> Bool) -> Bool {
        if node === TreeNode.SENTINEL {
            return callback(TreeNode.SENTINEL);
        }

        let leftRet = iterate(node: node.left!, callback: callback);
        if !leftRet {
            return leftRet;
        }

        return callback(node) && iterate(node: node.right!, callback: callback);
    }

    func getPieceContent(piece: Piece) -> V {

        let buffer = buffers[piece.bufferIndex]
        let startOffset = offsetInBuffer(piece.bufferIndex, piece.start)
        let endOffset = offsetInBuffer(piece.bufferIndex, piece.end)
        let currentContent = buffer.buffer [startOffset..<endOffset]
        return V (currentContent)
    }

    func offsetInBuffer(_ bufferIndex: Int, _ cursor: BufferCursor) -> V.Index
    {
        let stringBuffer = buffers[bufferIndex]
        let lineStarts = stringBuffer.lineStarts
        return stringBuffer.buffer.index(lineStarts[cursor.line], offsetBy: cursor.column)
    }

    func deleteNodes(_ nodes: [TreeNode])
    {
        for node in nodes {
            rbDelete (self, node)
        }
    }

    public func getOffsetAt(_ _lineNumber: Int, _ column: Int)-> Int {
        var leftLen = 0; // inorder
        var lineNumber = _lineNumber
        var x = root

        while x !== TreeNode.SENTINEL {
            if x.left !== TreeNode.SENTINEL && x.lf_left + 1 >= lineNumber {
                x = x.left!
            } else if x.lf_left + x.piece.lineFeedCount + 1 >= lineNumber {
                leftLen += x.size_left
                // lineNumber >= 2
                let accumualtedValInCurrentIndex = getAccumulatedValue(node: x, index: lineNumber - x.lf_left - 2)
                return leftLen + accumualtedValInCurrentIndex + column - 1
            } else {
                lineNumber -= x.lf_left + x.piece.lineFeedCount
                leftLen += x.size_left + x.piece.length
                x = x.right!
            }
        }

        return leftLen
    }

    func getAccumulatedValue(node: TreeNode, index: Int) -> Int { // V.IndexDistance
        guard index >= 0 else {
            return 0
        }

        let piece = node.piece
        let stringBuffer = buffers[piece.bufferIndex]
        let lineStarts = stringBuffer.lineStarts
        let expectedLineStartIndex = piece.start.line + index + 1
        if expectedLineStartIndex > piece.end.line {
            return stringBuffer.buffer.distance(
                from: stringBuffer.buffer.index(lineStarts[piece.start.line], offsetBy: piece.start.column),
                to: stringBuffer.buffer.index(lineStarts[piece.end.line], offsetBy: piece.end.column)
            )
        } else {
            return stringBuffer.buffer.distance(
                from: stringBuffer.buffer.index(lineStarts[piece.start.line], offsetBy: piece.start.column),
                to: lineStarts[expectedLineStartIndex]
            )
        }
    }

    func getNodeContent(_ node: TreeNode) -> V
    {
        if node === TreeNode.SENTINEL {
            return V()
        }
        let buffer = buffers [node.piece.bufferIndex]
        let piece = node.piece
        let startOffset = offsetInBuffer(piece.bufferIndex, piece.start)
        let endOffset = offsetInBuffer(piece.bufferIndex, piece.end)
        return V (buffer.buffer [startOffset..<endOffset])
    }


    /**
     *      node              node
     *     /  \              /  \
     *    a   b    <----   a    b
     *                     /
     *                    z
     */
    func rbInsertRight (_ node: TreeNode?, _ p: Piece) -> TreeNode {
        let z = TreeNode(p, .red)
        z.left = TreeNode.SENTINEL
        z.right = TreeNode.SENTINEL
        z.parent = TreeNode.SENTINEL
        z.size_left = 0
        z.lf_left = 0

        let x = root
        if x === TreeNode.SENTINEL {
            root = z
            z.color = .black
        } else if node!.right === TreeNode.SENTINEL {
            node!.right = z
            z.parent = node!
        } else {
            let nextNode = leftest(node!.right!)
            nextNode.left = z
            z.parent = nextNode
        }

        fixInsert(self, z)
        return z
    }


    /**
     *      node              node
     *     /  \              /  \
     *    a   b     ---->   a    b
     *               \
     *               z
     */
    func rbInsertLeft(node: TreeNode?, p: Piece) -> TreeNode {
        let z = TreeNode(p, .red)
        z.left = TreeNode.SENTINEL
        z.right = TreeNode.SENTINEL
        z.parent = TreeNode.SENTINEL
        z.size_left = 0
        z.lf_left = 0

        if root === TreeNode.SENTINEL {
            root = z
            z.color = .black
        } else if node!.left === TreeNode.SENTINEL {
            node!.left = z
            z.parent = node!
        } else {
            let prevNode = righttest(node!.left!) // a
            prevNode.right = z
            z.parent = prevNode
        }

        fixInsert(self, z);
        return z
    }

    func getContentOfSubTree(node: TreeNode) -> V {
        var str: V = V()

        iterate(node: node, callback: { node in
            str += getNodeContent(node)
            return true
        });

        return str
    }

    func computeBufferMetadata ()
    {
        var x = root
        var lfCnt = 1
        var len = 0;

        while x !== TreeNode.SENTINEL {
            lfCnt += x.lf_left + x.piece.lineFeedCount
            len += x.size_left + x.piece.length
            x = x.right!
        }

        lineCount = lfCnt
        length = len
        searchCache.validate(offset: length)
    }
}


