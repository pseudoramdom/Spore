import Foundation
import secp256k1

/// bech-32 encoding
///
/// Ref - [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
/// Ref - [BIP-173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)
public struct Bech32Coder {
    
    enum HumanReadablePart {
        public static let privateKey = "nsec"
        public static let publicKey = "npub"
        public static let note = "note"
        public static let profile = "nprofile"
        public static let event = "nevent"
        public static let relay = "nrelay"
    }
    
    private let characterSet: [Character] = Array("qpzry9x8gf2tvdw0s3jn54khce6mua7l")
    private let generator = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    
    public init() {}
    
    public func encode(humanReadablePart: String, _ string: String) throws -> String {
        let input = try string.bytes
        let bits = eightToFiveBits(input)
        let checksum = createChecksum(humanReadablePart: humanReadablePart, data: bits)
        let separator = "1"
        return "\(humanReadablePart)" + separator + String((bits + checksum).map { characterSet[Int($0)] })
    }
    
    public func decode(bech32String: String) throws -> (humanReadablePart: String, data: Data) {
        try validateCharacters(bech32String)
        
        let bech32String = bech32String.lowercased()
        
        guard let separatorPosition = bech32String.lastIndex(of: "1")?.utf16Offset(in: bech32String) else { throw Bech32DecodeError.missingSeparator }
        
        if separatorPosition < 1 || separatorPosition + 7 > bech32String.count || bech32String.count > 90 {
            throw Bech32DecodeError.missingSeparator
          }
        
        let humanReadablePart = String(bech32String.prefix(separatorPosition))
        let dataPart = bech32String.suffix(bech32String.count - humanReadablePart.count - 1)

        var data = Data()
        for character in dataPart {
            guard let distance = characterSet.firstIndex(of: character) else {
                throw Bech32DecodeError.invalidCharacter
            }
            data.append(UInt8(distance))
        }
        
        let byteArray = data.map { $0 }
        if !verifyChecksum(humanReadablePart: humanReadablePart, data: byteArray) {
            throw Bech32DecodeError.invalidChecksum
        }

        let outputData = Data(data[..<(data.count - 6)])
        guard let convertedData = convertBits(outbits: 8, input: outputData, inbits: 6, pad: 0) else {
            throw Bech32DecodeError.decodeFailed
        }
        return (humanReadablePart, convertedData)
    }
}

extension Bech32Coder {
    private func validateCharacters(_ bechString: String) throws {
        guard let stringBytes = bechString.data(using: .utf8) else {
            throw Bech32DecodeError.invalidInputString
        }
        
        var hasLower = false
        var hasUpper = false
        
        for character in stringBytes {
            let code = UInt32(character)
            if code < 33 || code > 126 {
                throw Bech32DecodeError.invalidCharacter
            } else if code >= 97 && code <= 122 {
                hasLower = true
            } else if code >= 65 && code <= 90 {
                hasUpper = true
            }
        }
        
        guard !(hasLower && hasUpper) else {
            throw Bech32DecodeError.caseMixing
        }
    }
    
    private func eightToFiveBits(_ input: [UInt8]) -> [UInt8] {
        guard !input.isEmpty else { return [] }
        
        var outputSize = (input.count * 8) / 5
        if ((input.count * 8) % 5) != 0 {
            outputSize += 1
        }
        var outputArray: [UInt8] = []
        for i in (0..<outputSize) {
            let devision = (i * 5) / 8
            let reminder = (i * 5) % 8
            var element = input[devision] << reminder
            element >>= 3
            
            if (reminder > 3) && (i + 1 < outputSize) {
                element = element | (input[devision + 1] >> (8 - reminder + 3))
            }
            
            outputArray.append(element)
        }
        
        return outputArray
    }
    
    private func createChecksum(humanReadablePart: String, data: [UInt8]) -> [UInt8] {
        let values = expandHumanReadablePart(humanReadablePart) + data
        let polymod = polymod(values + [0,0,0,0,0,0]) ^ 1
        var result: [UInt] = []
        for i in (0..<6) {
            result.append((polymod >> (5 * (5 - UInt(i)))) & 31)
        }
        return result.map { UInt8($0) }
    }
    
    private func expandHumanReadablePart(_ s: String) -> [UInt8] {
        var left: [UInt8] = []
        var right: [UInt8] = []
        for x in Array(s) {
            let scalars = String(x).unicodeScalars
            left.append(UInt8(scalars[scalars.startIndex].value) >> 5)
            right.append(UInt8(scalars[scalars.startIndex].value) & 31)
        }
        return left + [0] + right
    }
    
    private func polymod(_ values: [UInt8]) -> UInt {
        let GEN: [UInt] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
        var chk: UInt = 1
        for v in values {
            let b = (chk >> 25)
            chk = (chk & 0x1ffffff) << 5 ^ UInt(v)
            for i in (0..<5) {
                if (((b >> i) & 1) != 0) {
                    chk ^= GEN[i]
                }
            }
        }
        return chk
    }
    
    private func verifyChecksum(humanReadablePart: String, data: [UInt8]) -> Bool {
        return polymod(expandHumanReadablePart(humanReadablePart) + data) == 1
    }
    
    func convertBits(outbits: Int, input: Data, inbits: Int, pad: Int) -> Data? {
        let maxv: UInt32 = ((UInt32(1)) << outbits) - 1;
        var val: UInt32 = 0
        var bits: Int = 0
        var out = Data()
        
        for i in (0..<input.count) {
            val = (val << inbits) | UInt32(input[i])
            bits += inbits;
            while bits >= outbits {
                bits -= outbits;
                out.append(UInt8((val >> bits) & maxv))
            }
        }
        
        if pad != 0 {
            if bits != 0 {
                out.append(UInt8(val << (outbits - bits) & maxv))
            }
        } else if 0 != ((val << (outbits - bits)) & maxv) || bits >= inbits {
            return nil
        }
        
        return out
    }
}

public enum Bech32DecodeError: Error {
    case invalidCharacter
    case missingSeparator
    case caseMixing
    case invalidChecksum
    case invalidInputString
    case decodeFailed
}
