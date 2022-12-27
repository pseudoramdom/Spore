import Foundation

extension TestData.Event {
    static let validData = Data("""
    {
      "id": "dc90c95f09947507c1044e8f48bcf6350aa6bff1507dd4acfc755b9239b5c962",
      "pubkey": "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
      "created_at": 1644271588,
      "kind": 1,
      "tags": [
        ["e", "yetAnotherEventID", "recommendedRelayURL"],
        ["p", "yetAnotherPubKey", "anotherRecommendedRelayURL"],
        ["nonce", "3", "20"],
        ["delegation", "pubKey", "conditionsQuery", "signature"]
      ],
      "content": "Test Content",
      "sig": "230e9d8f0ddaf7eb70b5f7741ccfa37e87a455c9a469282e3464e2052d3192cd63a167e196e381ef9d7e69e9ea43af2443b839974dc85d8aaab9efe1d9296524"
    }
    """.utf8)
    
    static let unsupportedKind = Data("""
    {
      "id": "id",
      "pubkey": "pub",
      "created_at": 1,
      "kind": 73,
      "tags": [],
      "content": "",
      "sig": ""
    }
    """.utf8)
    
    static let unknownTag = Data("""
    {
      "id": "id",
      "pubkey": "pub",
      "created_at": 1,
      "kind": 1,
      "tags": [["randomTag", "asdad"]],
      "content": "",
      "sig": ""
    }
    """.utf8)
    
    static let pubkeyTag = Data("""
    {
      "id": "id",
      "pubkey": "pub",
      "created_at": 1,
      "kind": 1,
      "tags": [["p", "pubkey", "relayURL"]],
      "content": "",
      "sig": ""
    }
    """.utf8)
    
    static let contactListResponse = Data("""
{"id":"164e267e2ea8144aa12afddbdee929e2cf21304edc0c428f32bd0d20a95ad867","pubkey":"c2441dc0e1dee6d00beb480c707ba0e559a5089648fcf602d01af5959ca92ecc","created_at":1671920470,"kind":3,"tags":[["p","3efdaebb1d8923ebd99c9e7ace3b4194ab45512e2be79c1b7d68d9243e0d2681"]],"content":"","sig":"f47a23c3cdafb5ca080adb0bb56ac42d3a706bd4849324a47ead8d28c497e28284d3f1ea8ba09d06ac7f2ea02fd3cd1b39df214198e947810bde340da41733c5"}
""".utf8)
}
