//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 4/6/21.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (Result<[FeedItem], Error>) -> Void) {

        self.session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_FailsOnRequestError() {
        URLProtocolStub.startInterceptionRequest()

        let url = URL(string: "http://Any-url.com")!
        let error = NSError(domain: "AnyError", code: 99)
        URLProtocolStub.stub(data: nil, response: nil, error: error)

        let sut = URLSessionHTTPClient()

        let expect = expectation(description: "wait for completion")
        sut.get(from: url) { (result) in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
            default:
                XCTFail("Expected failure with error \(error), got \(result) insteed")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)

        URLProtocolStub.stopInterceptingRequest()
    }

    //MARK: - Helpers

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?

        private struct Stub {
            let data:Data?
            let response: HTTPURLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptionRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
