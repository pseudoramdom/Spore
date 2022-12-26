import Foundation

extension TestData.RelayMessage {
    static let validEventMessage = Data("""
    [
    "EVENT",
    "subID",
    {
      "id": "eventID",
      "pubkey": "pubKey",
      "created_at": 100,
      "kind": 3,
      "tags": [
        ["e", "eventID"],
        ["p", "pubKey2"]
      ],
      "content": "Test Content",
      "sig": "signature"
    }
    ]
    """.utf8)
    
    static let eventMessageMissingEvent = Data("""
    [
    "EVENT",
    "subID"
    ]
    """.utf8)
    
    static let eventMessageMissingContent = Data("""
    [
    "EVENT",
    "subID",
    {
      "id": "eventID",
      "pubkey": "pubKey",
      "created_at": 100,
      "kind": 3,
      "tags": [
        ["e", "eventID"],
        ["p", "pubKey2"]
      ],
      "sig": "signature"
    }
    ]
    """.utf8)
}

extension TestData.RelayMessage {
    static let validNoticeMessage = Data("""
    [
    "NOTICE",
    "message"
    ]
    """.utf8)
    
    static let noticeMessageMissingMessage = Data("""
    [
    "NOTICE"
    ]
    """.utf8)
}

extension TestData.RelayMessage {
    static let validEOSEMessage = Data("""
    [
    "EOSE",
    "subID"
    ]
    """.utf8)
    
    static let EOSEMessageMissingSubscriptionID = Data("""
    [
    "EOSE"
    ]
    """.utf8)
}

extension TestData.RelayMessage {
    static let validOkMessage = Data("""
    [
    "OK",
    "eventID",
    true,
    "message"
    ]
    """.utf8)
    
    static let okMessageMissingMessage = Data("""
    [
    "OK",
    "eventID",
    true
    ]
    """.utf8)
}
