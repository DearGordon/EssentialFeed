//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
import EssentialFeed

typealias SuccessItem = (Data, HTTPURLResponse)
typealias Message = (url: URL, completion: (Result<SuccessItem, Error>) -> Void)

class RemoteFeedLoaderTest: XCTestCase {

    func test_Init_DoesNotRequestDataFromURL() {

        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestURLs.isEmpty)
    }

    func test_Load_RequestsDataFromURL() {
        let url = URL(string: "https://yahoo.com.tw")!

        let (loader, client) = makeSUT(url: url)
        loader.load(completion: { _ in })

        XCTAssertEqual(client.requestURLs, [url])
    }

    func testCallRequestTwice() {
        let url = URL(string: "https://yahoo.com.tw")!
        let (loader, client) = makeSUT(url: url)
        loader.load(completion: { _ in })
        loader.load(completion: { _ in })
        XCTAssertEqual(client.requestURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (loader, client) = makeSUT()

        expect(loader, toCompleteWithResult: [.failure(.connectivity)], when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (loader, client) = makeSUT()
        let sample = [199, 201, 300, 400, 500]

        sample.enumerated().forEach { (index, code) in
            expect(loader, toCompleteWithResult: [.failure(.invalidData)], when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (loader, client) = makeSUT()

        expect(loader, toCompleteWithResult: [.failure(.invalidData)], when: {
            client.complete(withStatusCode: 200, data: Data())
        })
    }

    //MARK: - Helper
    private func makeSUT(url: URL = URL(string: "http://google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {

        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(url: url, client: client)
        return (loader, client)
    }

    private func expect(_ loader: RemoteFeedLoader,
                        toCompleteWithResult result: [Result<[FeedItem], RemoteFeedLoader.Error>],
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {

        var captureResult: [Result<[FeedItem], RemoteFeedLoader.Error>] = []

        loader.load { (result) in
            captureResult.append(result)
        }
        action()
        XCTAssertEqual(captureResult, result, file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages: [Message] = []

        var requestURLs: [URL] {
            return messages.map{ $0.url }
        }

        func get(form url: URL, completion: @escaping ((Result<SuccessItem, Error>) -> Void)) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!

            messages[index].completion(.success((data, response)))
        }
    }
}
