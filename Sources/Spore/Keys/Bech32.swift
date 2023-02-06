import Foundation
import secp256k1

/// bech-32 encoding
///
/// Ref - [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
/// Ref - [BIP-173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)
public struct Bech32Coder {
    
    /// human-readable part
    public typealias HRPPrefix = String
    
    enum Prefix {
        public static let privateKey: HRPPrefix = "nsec"
        public static let publicKey: HRPPrefix = "npub"
        public static let note: HRPPrefix = "note"
        public static let profile: HRPPrefix = "nprofile"
        public static let event: HRPPrefix = "nevent"
        public static let relay: HRPPrefix = "nrelay"
    }
    
    public init() {}
    
    public func encode(hrp: HRPPrefix, _ string: String) throws -> String {
        let input = try string.bytes
        let table: [Character] = Array("qpzry9x8gf2tvdw0s3jn54khce6mua7l")
        let bits = eightToFiveBits(input)
        let check_sum = checksum(hrp: hrp, data: bits)
        let separator = "1"
        return "\(hrp)" + separator + String((bits + check_sum).map { table[Int($0)] })
    }
    
    public func decode(bech32String: String) throws -> (hrp: HRPPrefix, string: String) {
        let bytes = try bech32String.bytes
        
        guard !(bytes.contains() { $0 < 33 || $0 > 126 }) else { throw Bech32DecodeError.invalidCharacter }
        
        // Decoders MUST NOT accept strings where some characters are uppercase and some are lowercase (such strings are referred to as mixed case strings)
        let hasLowercase = bytes.contains() { $0 >= 97 && $0 <= 122 }
        let hasUppercase = bytes.contains() { $0 >= 65 && $0 <= 90 }
          
        if hasLowercase && hasUppercase { throw Bech32DecodeError.caseMixing }
        
        let bech32String = bech32String.lowercased()
        
        guard let separatorPosition = bech32String.lastIndex(of: "1") else { throw Bech32DecodeError.missingSeparator }
        
        if separatorPosition < 1 || bech32String.characters.count > 90 {
            throw Bech32DecodeError.missingSeparator
          }
        
        let hrpSubString = bech32String.substring(to: bech32String.index(bech32String.startIndex, offsetBy: separatorPosition))
    }
    
    public func bech32_verify_checksum(hrp: String, data: [UInt8]) -> Bool {
        bech32_polymod(bech32_hrp_expand(hrp) + data) == 1
    }
}

extension Bech32Coder {
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
    
    private func checksum(hrp: HRPPrefix, data: [UInt8]) -> [UInt8] {
        let values = bech32_hrp_expand(hrp) + data
        let polymod = bech32_polymod(values + [0,0,0,0,0,0]) ^ 1
        var result: [UInt] = []
        for i in (0..<6) {
            result.append((polymod >> (5 * (5 - UInt(i)))) & 31)
        }
        return result.map { UInt8($0) }
    }
    
    private func bech32_hrp_expand(_ s: String) -> [UInt8] {
        var left: [UInt8] = []
        var right: [UInt8] = []
        for x in Array(s) {
            let scalars = String(x).unicodeScalars
            left.append(UInt8(scalars[scalars.startIndex].value) >> 5)
            right.append(UInt8(scalars[scalars.startIndex].value) & 31)
        }
        return left + [0] + right
    }
    
    private func bech32_polymod(_ values: [UInt8]) -> UInt {
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
}

public enum Bech32DecodeError: Error {
    case invalidCharacter
    case missingSeparator
    case caseMixing
}
