//
//  MessagesTests.swift
//  
//
//  Created by Ramsundar Shandilya on 12/19/22.
//

import XCTest
@testable import Spore

final class RelayMessageTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}

extension RelayMessageTests {
    
    func test_decodeRelayMessage_ValidEvent() throws {
        let messageData = TestData.RelayMessage.validEventMessage
        
        let decodedMessage = try JSONDecoder().decode(Message.Relay.self, from: messageData)
        
        XCTAssertEqual(decodedMessage.type, .event)
        
        guard let eventMessage = decodedMessage.message as? Message.Relay.EventMessage else {
            XCTFail("Message is not of type RelayMessageEvent")
            return
        }
        
        XCTAssertEqual(eventMessage.subscriptionId, "subID")
        XCTAssertEqual(eventMessage.event.id, "eventID")
    }
    
    func test_decodeRelayMessage_MissingEvent() throws {
        let messageData = TestData.RelayMessage.eventMessageMissingEvent
        
        do {
            _ = try JSONDecoder().decode(Message.Relay.self, from: messageData)
            XCTFail("Decode should have failed")
        } catch DecodingError.valueNotFound {
            return
        } catch {
            XCTFail("Error is \(error) and not .valueNotFound")
        }
    }
    
    func test_decodeRelayMessage_MissingContent() throws {
        let messageData = TestData.RelayMessage.eventMessageMissingContent
        
        do {
            _ = try JSONDecoder().decode(Message.Relay.self, from: messageData)
            XCTFail("Decode should have failed")
        } catch DecodingError.keyNotFound {
            return
        } catch {
            XCTFail("Error is \(error) and not .keyNotFound")
        }
    }
}

extension RelayMessageTests {
    func test_decodeRelayMessage_ValidNotice() throws {
        let messageData = TestData.RelayMessage.validNoticeMessage
        
        let decodedMessage = try JSONDecoder().decode(Message.Relay.self, from: messageData)
        
        XCTAssertEqual(decodedMessage.type, .notice)
        
        guard let noticeMessage = decodedMessage.message as? Message.Relay.NoticeMessage else {
            XCTFail("Message is not of type RelayMessageNotice")
            return
        }
        
        XCTAssertEqual(noticeMessage.message, "message")
    }
    
    func test_decodeRelayMessage_MissingNoticeMessage() throws {
        let messageData = TestData.RelayMessage.noticeMessageMissingMessage
        
        do {
            _ = try JSONDecoder().decode(Message.Relay.self, from: messageData)
            XCTFail("Decode should have failed")
        } catch DecodingError.valueNotFound {
            return
        } catch {
            XCTFail("Error is \(error) and not .valueNotFound")
        }
    }
}

extension RelayMessageTests {
    func test_decodeRelayMessage_ValidEOSE() throws {
        let messageData = TestData.RelayMessage.validEOSEMessage
        
        let decodedMessage = try JSONDecoder().decode(Message.Relay.self, from: messageData)
        
        XCTAssertEqual(decodedMessage.type, .endOfStoredEvents)
        
        guard let eoseMessage = decodedMessage.message as? Message.Relay.EndOfStoredEventsMessage else {
            XCTFail("Message is not of type RelayMessageEndOfStoredEvents")
            return
        }
        
        XCTAssertEqual(eoseMessage.subscriptionId, "subID")
    }
    
    func test_decodeRelayMessage_MissingSubscriptionID() throws {
        let messageData = TestData.RelayMessage.EOSEMessageMissingSubscriptionID
        
        do {
            _ = try JSONDecoder().decode(Message.Relay.self, from: messageData)
            XCTFail("Decode should have failed")
        } catch DecodingError.valueNotFound {
            return
        } catch {
            XCTFail("Error is \(error) and not .valueNotFound")
        }
    }
}

extension RelayMessageTests {
    func test_decodeRelayMessage_ValidOKMessage() throws {
        let messageData = TestData.RelayMessage.validOkMessage
        
        let decodedMessage = try JSONDecoder().decode(Message.Relay.self, from: messageData)
        
        XCTAssertEqual(decodedMessage.type, .ok)
        
        guard let okMessage = decodedMessage.message as? Message.Relay.OkMessage else {
            XCTFail("Message is not of type RelayMessageEndOfStoredEvents")
            return
        }
        
        XCTAssertEqual(okMessage.eventId, "eventID")
        XCTAssertTrue(okMessage.status)
        XCTAssertEqual(okMessage.message, "message")
    }

    func test_decodeRelayMessage_MissingEventID() throws {
        let messageData = TestData.RelayMessage.okMessageMissingMessage
        
        do {
            _ = try JSONDecoder().decode(Message.Relay.self, from: messageData)
            XCTFail("Decode should have failed")
        } catch DecodingError.valueNotFound {
            return
        } catch {
            XCTFail("Error is \(error) and not .valueNotFound")
        }
    }
}
