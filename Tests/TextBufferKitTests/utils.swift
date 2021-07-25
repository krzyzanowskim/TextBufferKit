//
//  utils.swift
//  TextBufferKitTests
//
//  Created by Marcin Krzyzanowski on 25/07/2021.
//

import Foundation

func toBytes (_ strs: [String]) -> [[UInt8]]
{
    var result: [[UInt8]] = []

    for str in strs {
        result.append (str.toBytes())
    }
    return result
}

extension String {

    func toBytes() -> [UInt8] {
        Array(utf8)
    }

    func substring (_ start: Int, _ end: Int) -> String
    {
        //
        // This is coded this way, because the documented:
        // let sidx = str.index (str.startIndex, offsetBy: start)
        // let eix = str.index (str.startIndex, offsetBy: end)
        // let result = self[sidx..<eidx] produces the expected [sidx,eidx) range for strings
        // but produces [sidx,eidx] range when the string contains "\r\r\n\n"
        let j = self.toBytes()
        return Array (j [start..<end]).toStr()
    }

    func substring (_ start: Int) -> String
    {
        if start > self.count {
            return ""
        }
        // This used to be coded like this:
        // return String (self [self.index(self.startIndex, offsetBy: start)...])
        // But swift decided that for the string "\r\r\n", the substring(2) is not "\n" but ""
        let j = self.toBytes()
        return Array (j [start...]).toStr()
    }
}

extension Array where Element == UInt8 {

    func toStr () -> String
    {
        String(bytes: self, encoding: .utf8)!
    }

    func substring (_ start: Int, _ end: Int) -> Self
    {
        Array (self [start..<end])
    }

    func substring (_ start: Int) -> Self
    {
        Array (self [start...])
    }
}
