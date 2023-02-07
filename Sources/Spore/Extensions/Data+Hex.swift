import Foundation

public extension Data {
    public var hexEncodedString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    
    public enum DecodingError: Error {
        case oddNumberOfCharacters
        case invalidHexCharacters([Character])
    }
    
    public init(hexString: String) throws {
        let string: String
        if hexString.hasPrefix("0x") {
            string = String(hexString.dropFirst(2))
        } else {
            string = hexString
        }

        // Convert the string to bytes for better performance
        guard let stringData = string.data(using: .ascii, allowLossyConversion: true) else {
            throw KeysError.invalidHexString
        }

        self.init(capacity: string.count / 2)
        let stringBytes = Array(stringData)
        for i in stride(from: 0, to: stringBytes.count, by: 2) {
            guard let high = Data.value(of: stringBytes[i]) else {
                throw KeysError.invalidHexString
            }
            if i < stringBytes.count - 1, let low = Data.value(of: stringBytes[i + 1]) {
                append((high << 4) | low)
            } else {
                append(high)
            }
        }
        
        /// -------
        //        guard hexString.count.isMultiple(of: 2) else {
        //            throw KeysError.invalidHexString
        //        }
        //
        //        let chars = hexString.map { $0 }
        //        let bytes = stride(from: 0, to: chars.count, by: 2)
        //            .map { String(chars[$0]) + String(chars[$0 + 1]) }
        //            .compactMap { UInt8($0, radix: 16) }
        //
        //        guard hexString.count / bytes.count == 2 else { throw KeysError.invalidHexString }
        //        self.init(bytes)
        
        //-------
        
        //        guard hexString.count.isMultiple(of: 2) else { throw DecodingError.oddNumberOfCharacters }
        //
        //        self = .init(capacity: hexString.utf8.count / 2)
        //
        //        for pair in hexString.unfoldSubSequences(ofMaxLength: 2) {
        //            guard let byte = UInt8(pair, radix: 16) else {
        //                let invalidCharacters = Array(pair.filter({ !$0.isHexDigit }))
        //                throw DecodingError.invalidHexCharacters(invalidCharacters)
        //            }
        //
        //            append(byte)
        //        }
        
        // ----
        
//        self = hexString
//            .dropFirst(hexString.hasPrefix("0x") ? 2 : 0)
//            .compactMap { $0.hexDigitValue.map { UInt8($0) } }
//            .reduce(into: (data: Data(capacity: hexString.count / 2), byte: nil as UInt8?)) { partialResult, nibble in
//                if let p = partialResult.byte {
//                    partialResult.data.append(p + nibble)
//                    partialResult.byte = nil
//                } else {
//                    partialResult.byte = nibble << 4
//                }
//            }.data
    }
    
    /// Converts an ASCII byte to a hex value.
    static func value(of nibble: UInt8) -> UInt8? {
        guard let letter = String(bytes: [nibble], encoding: .ascii) else { return nil }
        return UInt8(letter, radix: 16)
    }
}

private extension Collection {
    func unfoldSubSequences(ofMaxLength maxSequenceLength: Int) -> UnfoldSequence<SubSequence, Index> {
        sequence(state: startIndex) { current in
            guard current < endIndex else { return nil }
            
            let upperBound = index(current, offsetBy: maxSequenceLength, limitedBy: endIndex) ?? endIndex
            defer { current = upperBound }
            
            return self[current..<upperBound]
        }
    }
}
