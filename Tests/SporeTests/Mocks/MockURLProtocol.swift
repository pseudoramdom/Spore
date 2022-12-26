import Foundation

class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
//        client?.urlProtocol(self, didReceive: <#T##URLResponse#>, cacheStoragePolicy: .notAllowed)
//        client?.urlProtocol(<#T##protocol: URLProtocol##URLProtocol#>, didLoad: <#T##Data#>)
    }
    
    override func stopLoading() {
        
    }
}
