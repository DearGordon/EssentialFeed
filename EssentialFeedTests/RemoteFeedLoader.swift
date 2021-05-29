//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
@testable import EssentialFeed

protocol HTTPClient {
    func get(form url: URL)
}

class RemoteFeedLoader {

    let client: HTTPClient
    let url: URL

    init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

    func load() {
        //client.get(form: URL(string: "https://google.com")!)    //this will fail
        client.get(form: url)
    }
}

class RemoteFeedLoaderTest: XCTestCase {

    func testInitDoesNotRequestDataFromURL() {

        let (_, client) = makeSUT()

        XCTAssertNil(client.requestURL)
    }

    func testLoadRequestDataFromURL() {
        //check which url we are loading data from
        let url = URL(string: "https://yahoo.com.tw")!

        let (loader, client) = makeSUT(url: url)
        loader.load()

        XCTAssertEqual(client.requestURL, url)
    }

    //MARK: - Helper
    private func makeSUT(url: URL = URL(string: "http://google.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url, client: client), client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestURL: URL?

        func get(form url: URL) {
            requestURL = url
        }
    }
}
