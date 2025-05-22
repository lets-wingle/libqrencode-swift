//
//  QREncodeSwift.swift
//
//
//  Created by Nikolay Kapustin on 19.06.2020.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import libqrencode
import pngconvert

public enum QREncodeSwiftResult: Int32 {
    case success = 0
    case fileError = -1
    case memoryError = -2
    case initError = -3
    case writeError = -4
    case unexpectedString = -5000
    case noQrCode = -5001
    case unknownError = -5002
}

public class QREncodeSwift {
    public enum QRErrorLevel: UInt32 {
        case low=0, middle, high, max
    }
    public static func qr(
        from: String,
        level: QRErrorLevel = .middle,
        outputFileName:String = "qr.png",
        colorComponents: [Int]? = nil,
        caseSensivity:Bool = true
    ) -> QREncodeSwiftResult {
        guard let cQRStr = from.cString(using: .ascii) else { return .unexpectedString }
        let output = FileManager.default.fileSystemRepresentation(withPath: outputFileName)

        let qrCode = QRcode_encodeString(cQRStr, 0, QRecLevel.init(level.rawValue), QRencodeMode.init(2), caseSensivity ? Int32(1):Int32(0))
        let result: QREncodeSwiftResult

        guard let qrCode else {
            return .noQrCode
        }

        let rawResult: Int32
        if let colors = colorComponents {
            rawResult = writePNG(qrCode, output, makeByte(from: colors.cColorComponents))
        } else {
            rawResult = writePNG(qrCode, output, nil)
        }
        result = QREncodeSwiftResult(rawValue: rawResult) ?? .unknownError
        qrCode.deallocate()
        return result
    }

    private static func makeByte(from array: [CUnsignedChar]?) -> UnsafeMutablePointer<UInt8>? {
        guard let arr = array else {return nil}
        let count = arr.count
        let result: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: count)
        _ = result.initialize(from: arr)
        return result.baseAddress!
    }
}

extension Collection where Element == Int{
    var cColorComponents:[CUnsignedChar]? {
        guard let red = self.first, let green = self.dropFirst().first, let blue = self.dropFirst(2).first
            else {return nil}
        guard (0...255).contains(red), (0...255).contains(green), (0...255).contains(blue)
            else {return nil}
        let r = CUnsignedChar(red)
        let g = CUnsignedChar(green)
        let b = CUnsignedChar(blue)
        return [r, g, b, CUnsignedChar(255)]
    }
}
