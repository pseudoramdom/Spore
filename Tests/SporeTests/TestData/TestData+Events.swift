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
}
