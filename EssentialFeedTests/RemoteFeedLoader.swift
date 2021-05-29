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

        XCTAssertNil(client.requestURL)
    }

    //test load, behaviours is requests data from URL.
    func test_Load_RequestsDataFromURL() {
        //check which url we are loading data from
        let url = URL(string: "https://yahoo.com.tw")!

        let (loader, client) = makeSUT(url: url)
        loader.load()

        XCTAssertEqual(client.requestURL, url)
    }

    func testCallRequestTwice() {
        let url = URL(string: "https://yahoo.com.tw")!
        let (loader, client) = makeSUT(url: url)
        loader.load()
        loader.load()
        //make an array so we can check load count and load url
        XCTAssertEqual(client.requestURLs, [url, url])
    }

    //MARK: - Helper
    private func makeSUT(url: URL = URL(string: "http://google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url, client: client), client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestURL: URL?
        var requestURLs: [URL] = []

        func get(form url: URL) {
            requestURL = url
            requestURLs.append(url)
        }
    }
}
