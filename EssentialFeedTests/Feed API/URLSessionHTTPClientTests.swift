//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 4/6/21.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptionRequest()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }

    func test_getFromURL_performGETRequestWithURL() {
        let exp = expectation(description: "wait for completion call back")
        let url = anyURL()

        URLProtocolStub.observeRequests { request in
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
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil,                  error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil,                  error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil,       response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let receivedValue = resultValueFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedValue?.data, data)
        XCTAssertEqual(receivedValue?.response.url, response.url)
        XCTAssertEqual(receivedValue?.response.statusCode, response.statusCode)
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let anyHTTPResponse = anyHTTPURLResponse()

        let receivedValue = resultValueFor(data: nil, response: anyHTTPResponse, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedValue?.data, emptyData)
        XCTAssertEqual(receivedValue?.response.url, anyHTTPResponse.url)
        XCTAssertEqual(receivedValue?.response.statusCode, anyHTTPResponse.statusCode)
    }

    //MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func resultValueFor(data: Data?, response: HTTPURLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data:Data?, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)

        switch result {
        case let .success((receivedData, receivedResponse)):
            return (receivedData, receivedResponse)
        default:
            XCTFail("expect success but received \(result)", file: file, line: line)
            return nil
        }
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)

        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure but received \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Result<(Data, HTTPURLResponse), Error> {

        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "wait for completion")

        var receivedResult: Result<(Data, HTTPURLResponse), Error>!
        sut.get(from: anyURL()) { (result) in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
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

        static func observeRequests(_ completion: @escaping (URLRequest) -> Void) {
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
