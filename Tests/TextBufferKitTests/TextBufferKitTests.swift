//
//  TextBufferKitTests.swift
//  TextBufferKitTests
//
//  Created by Miguel de Icaza on 8/16/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import XCTest
@testable import TextBufferKit

class TextBufferKitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let builder = PieceTreeTextBufferBuilder<[UInt8]>()

        builder.acceptChunk("abc\n".toBytes())
        builder.acceptChunk("def".toBytes())
        let factory = builder.finish(normalizeEol: true)
        let pieceTree = factory.create(DefaultEndOfLine.LF).getPieceTree()

        XCTAssertEqual(pieceTree.lineCount, 2)
        XCTAssertEqual(pieceTree.getLineContent (1), "abc".toBytes())
        XCTAssertEqual(pieceTree.getLineContent(2), "def".toBytes())
        pieceTree.insert(1, [65])
        
        XCTAssertEqual(pieceTree.lineCount, 2)
        XCTAssertEqual(pieceTree.getLineContent (1), "aAbc".toBytes())
        XCTAssertEqual(pieceTree.getLineContent(2), "def".toBytes())
    }
    
    // More:
    // https://raw.githubusercontent.com/microsoft/vscode/master/src/vs/editor/test/common/model/pieceTreeTextBuffer/pieceTreeTextBuffer.test.ts

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
