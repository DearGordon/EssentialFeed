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

    struct UnexpectedValueRepresentation: Error {}

    func get(from url: URL, completion: @escaping (Result<[FeedItem], Error>) -> Void) {
        self.session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptionRequest()
    }

    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }

    func test_getFromURL_performGETRequestWithURL() {
        let exp = expectation(description: "wait for completion call back")
        let url = anyURL()

        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url, completion: { _ in })

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_FailsOnRequestError() {

        let error = anyError() as NSError
        let receivedError = resultErrorFor(data: nil, response: nil, error: error) as NSError?

        XCTAssertEqual(receivedError?.domain, error.domain)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {

        XCTAssertNotNil(resultErrorFor(data: nil,       response: nil,                  error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil,                  error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil,                  error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    //MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedError: Error?

        let exp = expectation(description: "wait for completion")
        sut.get(from: anyURL()) { (result) in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure but received \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedError
    }

    private func anyURL() -> URL {
        return URL(string: "Any-url.com")!
    }

    private func anyData() -> Data {
        return Data(bytes: "Any Data", count: 3)
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func anyError() -> Error {
        return NSError(domain: "Any Error", code: 0)
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var observeRequest: ((URLRequest) -> Void)?

        private struct Stub {
            let data:Data?
            let response: URLResponse?
            let error: Error?
        }

        static func observeRequest(_ completion: @escaping (URLRequest) -> Void) {
            observeRequest = completion
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptionRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            observeRequest = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            observeRequest?(request)
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
