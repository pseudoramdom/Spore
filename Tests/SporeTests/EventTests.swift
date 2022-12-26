//
//  EventsTest.swift
//  
//
//  Created by Ramsundar Shandilya on 12/18/22.
//

import XCTest
@testable import Spore

final class EventTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_DecodeEvent() throws {
        let eventData = TestData.Event.validData
        let decodedEvent = try JSONDecoder().decode(Event.SignedModel.self, from: eventData)
        
        XCTAssertEqual(decodedEvent.id, "dc90c95f09947507c1044e8f48bcf6350aa6bff1507dd4acfc755b9239b5c962")
        XCTAssertEqual(decodedEvent.publicKey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
        XCTAssertEqual(decodedEvent.createdAt, 1644271588)
        XCTAssertEqual(decodedEvent.kind, Event.Kind.textNote)
        
        // Verify tagtype event
        let tag1 = decodedEvent.tags[0]
        XCTAssertEqual(tag1.type.rawValue, Event.Tag.TagType.event.rawValue)
        
        guard let eventInfo = tag1.info as? Event.Tag.EventInfo else {
            XCTFail("Tag info should be EventInfo")
            return
        }
        XCTAssertEqual(eventInfo.eventId, "yetAnotherEventID")
        XCTAssertEqual(eventInfo.recommendedRelayURL, "recommendedRelayURL")
        
        // Verify tagtype pubkey
        let tag2 = decodedEvent.tags[1]
        XCTAssertEqual(tag2.type, Event.Tag.TagType.publicKey)
        
        guard let pubkeyInfo = tag2.info as? Event.Tag.PublicKeyInfo else {
            XCTFail("Tag info should be PublicKeyInfo")
            return
        }
        XCTAssertEqual(pubkeyInfo.publicKeyHexString, "yetAnotherPubKey")
        XCTAssertEqual(pubkeyInfo.recommendedRelayURL, "anotherRecommendedRelayURL")
        
        // Verify tagtype nonce
        let tag3 = decodedEvent.tags[2]
        XCTAssertEqual(tag3.type, Event.Tag.TagType.nonce)
        
        guard let nonceInfo = tag3.info as? Event.Tag.NonceInfo else {
            XCTFail("Tag info should be NonceInfo")
            return
        }
        XCTAssertEqual(nonceInfo.desiredLeadingZeroes, "3")
        XCTAssertEqual(nonceInfo.targetDifficulty, "20")
        
        // Verify tagtype delegation
        let tag4 = decodedEvent.tags[3]
        XCTAssertEqual(tag4.type, Event.Tag.TagType.delegation)
        
        guard let delegationInfo = tag4.info as? Event.Tag.DelegationInfo else {
            XCTFail("Tag info should be DelegationInfo")
            return
        }
        XCTAssertEqual(delegationInfo.publicKey, "pubKey")
        XCTAssertEqual(delegationInfo.conditionsQuery, "conditionsQuery")
        XCTAssertEqual(delegationInfo.signature, "signature")
        
        // Verify content
        XCTAssertEqual(decodedEvent.content, "Test Content")
        
        // verify sig
        XCTAssertEqual(decodedEvent.signature, "230e9d8f0ddaf7eb70b5f7741ccfa37e87a455c9a469282e3464e2052d3192cd63a167e196e381ef9d7e69e9ea43af2443b839974dc85d8aaab9efe1d9296524")
    }

//    func test_DecodeEventKindUnsupported() throws {
//        let eventData = TestData.Event.unsupportedKind
//        let decodedEvent = try JSONDecoder().decode(Event.SignedModel.self, from: eventData)
//        XCTAssertEqual(decodedEvent.kind, .unsupported)
//    }
//
//    func test_DecodeEventTagUnknown() throws {
//        let eventData = TestData.Event.unknownTag
//        let decodedEvent = try JSONDecoder().decode(Event.SignedModel.self, from: eventData)
//        XCTAssertEqual(decodedEvent.tags[0].type, .unsupported)
//    }

    
}
