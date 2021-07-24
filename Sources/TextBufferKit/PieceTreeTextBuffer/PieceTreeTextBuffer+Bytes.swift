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

extension PieceTreeTextBuffer where V == [UInt8] {

    convenience init(chunks: inout [StringBuffer<V>], BOM: V, eol: V, containsRTL: Bool, isBasicASCII: Bool, eolNormalized: Bool)
    {
        let pieceTree = PieceTreeBase(chunks: &chunks, eol: eol, eolNormalized: eolNormalized)
        self.init(BOM: BOM, eol: eol, pieceTree: pieceTree, containsRTL: containsRTL, isBasicASCII: isBasicASCII, eolNormalized: eolNormalized)
    }

    public var eol: V {
        get { pieceTree.eol }
        set {
            if newValue == V([10]) || newValue == V([10, 13]) {
                pieceTree.eol = newValue
            }
        }
    }

    // #region TextBuffer
    public static func == (left:PieceTreeTextBuffer, right: PieceTreeTextBuffer) -> Bool
    {
        if (left.bom != right.bom) {
            return false
        }
        if (left.eol != right.eol) {
            return false
        }
        return PieceTreeBase.equal (left: left.pieceTree, right: right.pieceTree)
    }

    public func createSnapshot (preserveBOM: Bool) -> PieceTreeSnapshot<V>
    {
        return pieceTree.createSnapshot(bom: preserveBOM ? bom: V())
    }

    public func getOffsetAt(lineNumber: Int, column: Int) ->  Int
    {
        return pieceTree.getOffsetAt(lineNumber, column)
    }

    public func delete (offset: Int, count: Int) {
        pieceTree.delete(offset: offset, cnt: count)
    }

    public var lineCount: Int {
        get {
            return pieceTree.lineCount
        }
    }

    public func insert (offset: Int, value: V) {
        pieceTree.insert(offset, value)
    }

    public func getPositionAt(offset: Int) ->  Position
    {
        return pieceTree.getPositionAt(offset)
    }

    public func getRangeAt(start: Int, length: Int) -> Range<V>
    {
        let end = start + length
        let startPosition = getPositionAt(offset: start)
        let endPosition = getPositionAt(offset: end)
        return Range(startLineNumber: startPosition.line, startColumn: startPosition.column, endLineNumber: endPosition.line, endColumn: endPosition.column)
    }

    public func getValueInRange(range: Range<V>, eol: EndOfLinePreference = EndOfLinePreference.TextDefined) ->  V {

        if range.isEmpty {
            return V()
        }
        let lineEnding = _getEndOfLine(eol: eol)
        return pieceTree.getValueInRange(range: range, eol: lineEnding)
    }

    public func getValueAt (index: Int) -> V.Element? {
        let b = getValueInRange(range: Range.from(start: index, end: index+1, on: self))
        return b.first
    }

    public func getValueLengthInRange(range: Range<V>, eol: EndOfLinePreference = EndOfLinePreference.TextDefined) ->  Int
    {
        if range.isEmpty {
            return 0
        }

        if range.startLineNumber == range.endLineNumber {
            return (range.endColumn - range.startColumn)
        }

        let startOffset = getOffsetAt(lineNumber: range.startLineNumber, column: range.startColumn)
        let endOffset = getOffsetAt(lineNumber: range.endLineNumber, column: range.endColumn)
        return endOffset - startOffset
    }

    public func getLength() ->  Int {
        return pieceTree.length
    }

    public func getLineCount() ->  Int {
        return pieceTree.lineCount
    }

    // Returns an array of lines, each line containing an array of bytes for the line, usually used as an UTF* buffer
    public func getLinesContent() -> [V] {
        return pieceTree.getLinesContent()
    }

    /// Returns the contents of the buffer as a byte array
    public func getLinesRawContent() -> V {
        return pieceTree.getLinesRawContent()
    }

    /// Returns the contents of the specified line as a byte array
    /// - Parameter lineNumber: the line to look up, starting at line 1
    public func getLineContent(_ lineNumber: Int) -> V {
        return pieceTree.getLineContent(lineNumber)
    }

    /// Returns the content of the byte at the line `lineNumber` at offset `index`
    /// - Parameter lineNumber: the line to look up, starting at line 1
    /// - Parameter index: 0-based index to the element to retrieve
    /// - Returns: The byte at the specified position
    public func getLineCharCode(lineNumber: Int, index: Int) ->  V.Element {
        return pieceTree.getLineCharCode(lineNumber: lineNumber, index: index)
    }

    /// Returns the number of bytes in the line at `lineNumber`
    /// - Parameter lineNumber: the line to look up, starting at line 1
    /// - Returns: the number of bytes in the line
    public func getLineLength(lineNumber: Int) ->  Int {
        return pieceTree.getLineLength(lineNumber: lineNumber)
    }

    public func getLineMinColumn(lineNumber: Int) ->  Int {
        return 1
    }

    public func getLineMaxColumn(lineNumber: Int) ->  Int {
        return getLineLength(lineNumber: lineNumber) + 1
    }

    static func firstNonWhitespaceIndex (_ str: V) -> Int
    {
        let top = str.count
        var i = 0
        while i < top {
            let code = str [i]
            if code != 32 /* space */ && code != 9 /* tab */ {
                return i
            }
            i += 1
        }
        return -1
    }

    func getLineFirstNonWhitespaceColumn(lineNumber: Int) ->  Int {
        let result = Self.firstNonWhitespaceIndex(getLineContent(lineNumber))
        if result == -1 {
            return 0
        }
        return result + 1
    }

    static func lastNonWhitespaceIndex(_ str: V, startIndex: Int = -1) -> Int
    {
        for i in (0..<(startIndex == -1 ? str.count-1 : startIndex)).reversed() {
            let code = str [i]
            if code != 32 /* space */ && code != 9 /* TAB */ {
                return i
            }
        }
        return -1
    }

    public func getLineLastNonWhitespaceColumn(lineNumber: Int) ->  Int {
        let result = Self.lastNonWhitespaceIndex(getLineContent(lineNumber))
        if result == -1 {
            return 0
        }
        return result + 2
    }

    func _getEndOfLine(eol: EndOfLinePreference) -> V {
        switch (eol) {
        case EndOfLinePreference.LF:
            return V([10])
        case EndOfLinePreference.CRLF:
            return V([13, 10])
        case EndOfLinePreference.TextDefined:
            return self.eol
        }
    }

    static func containsRTL (_ str: V) -> Bool
    {
        // TODO: needs to scan the string to determine if it contains RTL characters.
        return false
    }

    static func isBasicASCII (_ str: V) -> Bool
    {
        for a in str {
            if !(a == 9 /* TAB */ || a == 10 || a == 13 || (a >= 0x20 && a <= 0x7e)) {
                return false
            } else {
                return false
            }
        }
        return true
    }

    public enum UsageError: Error {
        case overlappingRanges
    }

    public func applyEdits(rawOperations: [IdentifiedSingleEditOperation<V>], recordTrimAutoWhitespace: Bool) throws ->  ApplyEditsResult<V>
    {
        var mightContainRTL = self.mightContainRTL
        var mightContainNonBasicASCII = self.mightContainNonBasicASCII;
        var canReduceOperations = true

        var operations: [ValidatedEditOperation<V>] = []
        for i in 0..<rawOperations.count {
            let op = rawOperations[i]
            if (canReduceOperations && op.isTracked) {
                canReduceOperations = false
            }
            let validatedRange = op.range
            if let optext = op.text {
                if !mightContainRTL {
                    // check if the new inserted text contains RTL
                    mightContainRTL = Self.containsRTL(optext)
                }
                if !mightContainNonBasicASCII {
                    mightContainNonBasicASCII = !Self.isBasicASCII(optext)
                }
            }
            operations[i] = ValidatedEditOperation<V>(
                sortIndex: i,
                identifier: op.identifier,
                range: validatedRange,
                rangeOffset:  getOffsetAt(lineNumber: validatedRange.startLineNumber, column: validatedRange.startColumn),
                rangeLength: getValueLengthInRange(range: validatedRange),
                lines: op.text != nil ? op.text!.split (separator: 10).map ({V ($0)}) : nil,
                forceMoveMarkers: op.forceMoveMarkers,
                isAutoWhitespaceEdit: op.isAutoWhitespaceEdit ?? false)

        }

        // Sort operations ascending
        operations.sort(by: { a, b in
            let r = Range.compareUsingEnds(a.range, b.range)
            if (r == 0) {
                return (a.sortIndex - b.sortIndex) < 0
            }
            return r < 0
        })

        var hasTouchingRanges = false
        for i in 0..<operations.count-1 {
            let rangeEnd = operations[i].range.endPosition
            let nextRangeStart = operations[i + 1].range.startPosition

            if (nextRangeStart.isBeforeOrEqual(rangeEnd)) {
                if (nextRangeStart.isBefore(rangeEnd)) {
                    // overlapping ranges
                    throw UsageError.overlappingRanges
                }
                hasTouchingRanges = true
            }
        }

        if (canReduceOperations) {
            operations = _reduceOperations(operations: operations)
        }

        // Delta encode operations
        let reverseRanges = PieceTreeTextBuffer._getInverseEditRanges(operations)
        var newTrimAutoWhitespaceCandidates: [(lineNumber: Int, oldContent: V)] = []

        var i = 0
        while i < operations.count {
            let op = operations[i]
            let reverseRange = reverseRanges[i]
            i += 1

            if (recordTrimAutoWhitespace && op.isAutoWhitespaceEdit && op.range.isEmpty) {
                // Record already the future line Ints that might be auto whitespace removal candidates on next edit
                for lineNumber in reverseRange.startLineNumber...reverseRange.endLineNumber {
                    var currentLineContent : V = V()
                    if (lineNumber == reverseRange.startLineNumber) {
                        currentLineContent = getLineContent(op.range.startLineNumber)
                        if Self.firstNonWhitespaceIndex(currentLineContent) != -1 {
                            continue
                        }
                    }
                    newTrimAutoWhitespaceCandidates.append((lineNumber: lineNumber, oldContent: currentLineContent))
                }
            }
        }

        var reverseOperations: [ReverseSingleEditOperation<V>] = []
        i = 0
        while i < operations.count {
            let op = operations[i]
            let reverseRange = reverseRanges[i]

            reverseOperations[i] = ReverseSingleEditOperation(
                sortIndex: op.sortIndex,
                identifier: op.identifier,
                range: reverseRange,
                text: getValueInRange(range: op.range),
                forceMoveMarkers: op.forceMoveMarkers,
                isAutoWhitespaceEdit: nil,
                isTracked: false /* right value? */)
            i += 1
        }

        // Can only sort reverse operations when the order is not significant
        if !hasTouchingRanges {
            reverseOperations.sort(by: { ($0.sortIndex - $1.sortIndex) < 0 })
        }

        self.mightContainRTL = mightContainRTL
        self.mightContainNonBasicASCII = mightContainNonBasicASCII

        let contentChanges = _doApplyEdits(operations: &operations)

        var trimAutoWhitespacelineNumbers: [Int]? = nil
        if recordTrimAutoWhitespace && newTrimAutoWhitespaceCandidates.count > 0 {
            // sort line Ints auto whitespace removal candidates for next edit descending
            newTrimAutoWhitespaceCandidates.sort(by: { ($1.lineNumber - $0.lineNumber) < 0})

            trimAutoWhitespacelineNumbers = []
            i = 0
            let len = newTrimAutoWhitespaceCandidates.count
            while i < len {
                let lineNumber = newTrimAutoWhitespaceCandidates[i].lineNumber
                i += 1
                if i > 0 && newTrimAutoWhitespaceCandidates[i - 1].lineNumber == lineNumber {
                    // Do not have the same line Int twice
                    continue
                }

                let prevContent = newTrimAutoWhitespaceCandidates[i].oldContent
                let lineContent = getLineContent(lineNumber)

                if (lineContent.count == 0 || lineContent == prevContent || Self.firstNonWhitespaceIndex(lineContent) != -1) {
                    continue
                }

                trimAutoWhitespacelineNumbers?.append(lineNumber)
            }
        }

        return ApplyEditsResult (reverseEdits: reverseOperations, changes: contentChanges, trimAutoWhitespaceLineNumbers: trimAutoWhitespacelineNumbers)
    }

    /**
     * Transform operations such that they represent the same logic edit,
     * but that they also do not cause OOM crashes.
     */
    func _reduceOperations(operations: [ValidatedEditOperation<V>]) ->  [ValidatedEditOperation<V>] {
        if operations.count < 1000 {
            // We know from empirical testing that a thousand edits work fine regardless of their shape.
            return operations
        }

        // At one point, due to how events are emitted and how each operation is handled,
        // some operations can trigger a high amount of temporary String allocations,
        // that will immediately get edited again.
        // e.g. a formatter inserting ridiculous ammounts of \n on a model with a single line
        // Therefore, the strategy is to collapse all the operations into a huge single edit operation
        return [_toSingleEditOperation(operations)]
    }

    func _toSingleEditOperation(_ operations: [ValidatedEditOperation<V>]) -> ValidatedEditOperation<V>
    {
        var forceMoveMarkers = false
        let firstEditRange = operations[0].range
        let lastEditRange = operations[operations.count - 1].range
        let entireEditRange = Range<V>(startLineNumber: firstEditRange.startLineNumber, startColumn: firstEditRange.startColumn, endLineNumber: lastEditRange.endLineNumber, endColumn: lastEditRange.endColumn)
        var lastendLineNumber = firstEditRange.startLineNumber
        var lastEndColumn = firstEditRange.startColumn
        var result: V = V()

        for operation in operations {
            let range = operation.range

            forceMoveMarkers = forceMoveMarkers || operation.forceMoveMarkers

            // (1) -- Push old text
            for lineNumber in lastendLineNumber..<range.startLineNumber {
                if (lineNumber == lastendLineNumber) {
                    result.append(contentsOf: getLineContent(lineNumber) [(lastEndColumn-1)...])
                } else {
                    result.append (10)
                    result.append(contentsOf: getLineContent(lineNumber))
                }
            }

            if (range.startLineNumber == lastendLineNumber) {
                result.append (contentsOf: getLineContent(range.startLineNumber) [(lastEndColumn - 1)..<(range.startColumn - 1)])
            } else {
                result.append (10)
                result.append(contentsOf: getLineContent(range.startLineNumber) [0..<(range.startColumn - 1)])
            }

            // (2) -- Push new text
            if let oplines = operation.lines {
                var j = 0
                let lenJ = oplines.count
                while j < lenJ {
                    if (j != 0) {
                        result.append (10)
                    }
                    result.append(contentsOf: oplines[j])
                    j += 1
                }
            }

            lastendLineNumber = operation.range.endLineNumber
            lastEndColumn = operation.range.endColumn
        }

        let llines = result.split(separator: 10, maxSplits: Int.max, omittingEmptySubsequences: false).map ({ V ($0) })

        return ValidatedEditOperation (sortIndex: 0,
                                       identifier: operations [0].identifier,
                                       range: entireEditRange,
                                       rangeOffset: getOffsetAt(lineNumber: entireEditRange.startLineNumber, column: entireEditRange.startColumn),
                                       rangeLength: getValueLengthInRange(range: entireEditRange),
                                       lines: llines,
                                       forceMoveMarkers: forceMoveMarkers,
                                       isAutoWhitespaceEdit: false)
    }

    func _doApplyEdits(operations: inout [ValidatedEditOperation<V>]) -> [InternalModelContentChange<V>]
    {
        operations.sort(by: { a, b in
            let r = Range.compareUsingEnds(a.range, b.range)
            if (r == 0) {
                return (a.sortIndex - b.sortIndex) > 0
            }
            return r > 0
        })

        var contentChanges: [InternalModelContentChange<V>] = []

        // operations are from bottom to top
        for op in operations {
            let startLineNumber = op.range.startLineNumber
            let startColumn = op.range.startColumn
            let endLineNumber = op.range.endLineNumber
            let endColumn = op.range.endColumn

            if startLineNumber == endLineNumber && startColumn == endColumn && (op.lines != nil || op.lines!.count == 0) {
                // no-op
                continue
            }

            let deletingLinesCnt = endLineNumber - startLineNumber
            let insertingLinesCnt = (op.lines != nil ? op.lines!.count - 1 : 0)
            let editingLinesCnt = min(deletingLinesCnt, insertingLinesCnt)

            let text: V = (op.lines != nil ? V (op.lines!.joined(separator: eol)) : V())

            if text.count > 0 {
                // replacement
                pieceTree.delete(offset: op.rangeOffset, cnt: op.rangeLength)
                pieceTree.insert(op.rangeOffset, text, eolNormalized: true)

            } else {
                // deletion
                pieceTree.delete(offset: op.rangeOffset, cnt: op.rangeLength)
            }

            if (editingLinesCnt < insertingLinesCnt) {
                var newLinesContent: [V] = []
                for j in (editingLinesCnt + 1)..<insertingLinesCnt {
                    newLinesContent.append (op.lines![j])
                }

                newLinesContent[newLinesContent.count - 1] = getLineContent(startLineNumber + insertingLinesCnt - 1)
            }

            let contentChangeRange = Range<V>(startLineNumber: startLineNumber, startColumn: startColumn, endLineNumber: endLineNumber, endColumn: endColumn)
            contentChanges.append(InternalModelContentChange(
                range: contentChangeRange,
                rangeOffset: op.rangeOffset,
                rangeLength: op.rangeLength,
                text: text,
                forceMoveMarkers: op.forceMoveMarkers
            ))
        }
        return contentChanges
    }
    //
    //    func findMatchesLineByLine(searchRange: Range, searchData: SearchData, captureMatches: Bool, limitResultCount: Int) ->  [FindMatch]
    //    {
    //        return pieceTree.findMatchesLineByLine(searchRange, searchData, captureMatches, limitResultCount)
    //    }
    //
    //    // #endregion
    //
    // #region helper
    // testing purpose.
    public func getPieceTree() ->  PieceTreeBase<V>
    {
        return pieceTree
    }

    /**
     * Assumes `operations` are validated and sorted ascending
     */
    public static func _getInverseEditRanges(_ operations: [ValidatedEditOperation<V>]) ->  [Range<V>] {
        var result: [Range<V>] = []
        var prevOpendLineNumber: Int = 0
        var prevOpEndColumn: Int = 0
        var prevOpNil: ValidatedEditOperation<V>? = nil
        for op in operations {
            var startLineNumber: Int
            var startColumn: Int

            if let prevOp = prevOpNil {
                if prevOp.range.endLineNumber == op.range.startLineNumber {
                    startLineNumber = prevOpendLineNumber
                    startColumn = prevOpEndColumn + (op.range.startColumn - prevOp.range.endColumn)
                } else {
                    startLineNumber = prevOpendLineNumber + (op.range.startLineNumber - prevOp.range.endLineNumber)
                    startColumn = op.range.startColumn
                }
            } else {
                startLineNumber = op.range.startLineNumber
                startColumn = op.range.startColumn
            }

            var resultRange: Range<V>

            if op.lines != nil && op.lines!.count > 0{
                let oplines = op.lines!
                let lineCount = oplines.count
                // the operation inserts something
                let firstLine = oplines[0]
                let lastLine = oplines[lineCount - 1]

                if lineCount == 1 {
                    // single line insert
                    resultRange = Range(startLineNumber: startLineNumber, startColumn: startColumn, endLineNumber: startLineNumber, endColumn: startColumn + firstLine.count)
                } else {
                    // multi line insert
                    resultRange = Range(startLineNumber: startLineNumber, startColumn: startColumn, endLineNumber: startLineNumber + lineCount - 1, endColumn: lastLine.count + 1)
                }
            } else {
                // There is nothing to insert
                resultRange = Range(startLineNumber: startLineNumber, startColumn: startColumn, endLineNumber: startLineNumber, endColumn: startColumn)
            }

            prevOpendLineNumber = resultRange.endLineNumber
            prevOpEndColumn = resultRange.endColumn

            result.append (resultRange)
            prevOpNil = op
        }

        return result
    }

    //    func static _sortOpsAscending(a: IValidatedEditOperation, b: IValidatedEditOperation) ->  Int
    //    {
    //        let r = Range.compareRangesUsingEnds(a.range, b.range)
    //        if (r === 0) {
    //            return a.sortIndex - b.sortIndex
    //        }
    //        return r
    //    }
    //
    //    func static _sortOpsDescending(a: IValidatedEditOperation, b: IValidatedEditOperation) ->  Int
    //    {
    //        let r = Range.compareRangesUsingEnds(a.range, b.range)
    //        if (r === 0) {
    //            return b.sortIndex - a.sortIndex
    //        }
    //        return -r
    //    }
    //    #endif
}
