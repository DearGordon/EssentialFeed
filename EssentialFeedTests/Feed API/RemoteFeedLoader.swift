//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
import EssentialFeed

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

        expect(loader, toCompleteWithResult: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (loader, client) = makeSUT()
        let sample = [199, 201, 300, 400, 500]

        sample.enumerated().forEach { (index, code) in
            expect(loader, toCompleteWithResult: failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (loader, client) = makeSUT()

        expect(loader, toCompleteWithResult: failure(.invalidData), when: {
            client.complete(withStatusCode: 200, data: Data())
        })
    }

    func test_load_deliverNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (loader, client) = makeSUT()

        expect(loader, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItem() {
        let (loader, client) = makeSUT()
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://google.com")!)
        let item2 = makeItem(id: UUID(), imageURL: URL(string: "http://yahoo.com.tw")!)

        let items = [item1.model, item2.model]

        expect(loader, toCompleteWithResult: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://google.com")!
        let client = HTTPClientSpy()
        var loader: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var captureResults:[Result<[FeedItem], Error>] = []
        loader?.load(completion: { captureResults.append($0) })

        loader = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(captureResults.isEmpty)
    }

    //MARK: - Helper
    private func makeSUT(url: URL = URL(string: "http://google.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {

        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (loader, client)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> Result<[FeedItem], Error> {
        return .failure(error)
    }

    private func makeItem(id: UUID,
                          description: String? = nil,
                          location: String? = nil,
                          imageURL: URL) -> (model: FeedItem, json: [String: Any]) {

        let item = FeedItem(id: id,
                            description: description,
                            location: location,
                            imageURL: imageURL)

        let json: [String : Any] = ["id": id.uuidString,
                                    "description": description,
                                    "location": location,
                                    "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (newDict, element) in
            //if there is nil in value, we don't add the key of that value into json
            if let value = element.value { newDict[element.key] = value }
        }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ loader: RemoteFeedLoader,
                        toCompleteWithResult expectResult: Result<[FeedItem], Error>,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {

        let exp = expectation(description: "wait for load completion")

        loader.load { (receivedResult) in
            switch (receivedResult, expectResult) {
            case let (.success(receivedItem), .success(expectItem)):
                XCTAssertEqual(receivedItem, expectItem, file: file, line: line)

            case let (.failure(receiveError as RemoteFeedLoader.Error), .failure(expectError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receiveError, expectError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectResult) got \(receivedResult), insteed", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
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

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!

            messages[index].completion(.success((data, response)))
        }
    }
}
