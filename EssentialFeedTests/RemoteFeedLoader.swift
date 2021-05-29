//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTest: XCTestCase {

    func test_Init_DoesNotRequestDataFromURL() {

        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestURLs.isEmpty)
    }

    //test load, behaviours is requests data from URL.
    func test_Load_RequestsDataFromURL() {
        //check which url we are loading data from
        let url = URL(string: "https://yahoo.com.tw")!

        let (loader, client) = makeSUT(url: url)
        loader.load()

        XCTAssertEqual(client.requestURLs, [url])
    }

    func testCallRequestTwice() {
        let url = URL(string: "https://yahoo.com.tw")!
        let (loader, client) = makeSUT(url: url)
        loader.load()
        loader.load()
        //make an array so we can check load count and load url
        XCTAssertEqual(client.requestURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        //ARRANGE: Given the sut and its HTTP client spy
        let (loader, client) = makeSUT()

        //ACT: when we tell the sut to load and we complete the client's HTTP request with an error
        var captureErrors: [RemoteFeedLoader.Error] = []
        loader.load { (result) in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                //here we capture an error and add to captureErrors
                captureErrors.append(error)
            }
        }
        let clientError = NSError(domain: "Test", code: 0)
        //the first completion block is if receive error, then return .connectivity error, so we created an clientError for it to receive, and then come the connectivity
        client.complete(with: clientError)
        //ASSERT: Then we expect the captured load error to be a connectivity error
        XCTAssertEqual(captureErrors, [.connectivity])
    }

    //MARK: - Helper
    private func makeSUT(url: URL = URL(string: "http://google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url, client: client), client)
    }

    private class HTTPClientSpy: HTTPClient {

        var requestURLs: [URL] = []
        var completions: [(Error) -> Void] = []

        func get(form url: URL, completion: @escaping ((Error) -> Void)) {
            completions.append(completion)
            requestURLs.append(url)
        }

        func complete(with error: Error, at index: Int = 0) {
            completions[index](error)
        }
    }
}
