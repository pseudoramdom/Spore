import XCTest
@testable import Spore

final class Bech32Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBech32_encodePubKey() throws {
        let publicKeyHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let bech32String = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        
        let result = try Bech32Coder().encode(humanReadablePart: Bech32Coder.HumanReadablePart.publicKey, publicKeyHex)
        XCTAssertEqual(result, bech32String)
    }
    
    func testBech32_encodePrivateKey() throws {
        let privateKeyHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let bech32String = "nsec180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsgyumg0"
        
        let result = try Bech32Coder().encode(humanReadablePart: Bech32Coder.HumanReadablePart.privateKey, privateKeyHex)
        XCTAssertEqual(result, bech32String)
    }
    
    func testBech32_decodePubKey() throws {
        let bech32String = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        let publicKeyHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        
        let result = try Bech32Coder().decode(bech32String: bech32String)
        XCTAssertEqual(result.humanReadablePart, Bech32Coder.HumanReadablePart.publicKey)
        XCTAssertEqual(result.data.hexEncodedString, publicKeyHex)
    }

    func testBech32_decodeFailed_missingSeparator() throws {
        let bech32String = "somerandomhumanreadablepart"
        
        do {
            _ = try Bech32Coder().decode(bech32String: bech32String)
            XCTFail("Decode should have failed")
        } catch Bech32DecodeError.missingSeparator {
            return
        } catch {
            XCTFail("Error is \(error) and not .missingSeparator")
        }
    }
    
    func testBech32_decodeFailed_caseMixing() throws {
        let bech32String = "mixedCASED"
        
        do {
            _ = try Bech32Coder().decode(bech32String: bech32String)
            XCTFail("Decode should have failed")
        } catch Bech32DecodeError.caseMixing {
            return
        } catch {
            XCTFail("Error is \(error) and not .caseMixing")
        }
    }
    
    func testBech32_decodeFailed_invalidCharacter() throws {
        let bech32String = " "
        
        do {
            _ = try Bech32Coder().decode(bech32String: bech32String)
            XCTFail("Decode should have failed")
        } catch Bech32DecodeError.invalidCharacter {
            return
        } catch {
            XCTFail("Error is \(error) and not .invalidCharacter")
        }
    }
}
