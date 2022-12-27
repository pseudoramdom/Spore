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
    
    static let contactListResponse = Data(#"""
["EVENT","F4A57529-B6EE-4340-BC72-E0886E95D961",{"id":"164e267e2ea8144aa12afddbdee929e2cf21304edc0c428f32bd0d20a95ad867","pubkey":"c2441dc0e1dee6d00beb480c707ba0e559a5089648fcf602d01af5959ca92ecc","created_at":1671920470,"kind":3,"tags":[["p","3efdaebb1d8923ebd99c9e7ace3b4194ab45512e2be79c1b7d68d9243e0d2681"]],"content":"","sig":"f47a23c3cdafb5ca080adb0bb56ac42d3a706bd4849324a47ead8d28c497e28284d3f1ea8ba09d06ac7f2ea02fd3cd1b39df214198e947810bde340da41733c5"}]
"""#.utf8)
}
