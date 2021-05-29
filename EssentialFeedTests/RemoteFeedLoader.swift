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

class HTTPClientSpy: HTTPClient {
    var requestURL: URL?

    func get(form url: URL) {
        requestURL = url
    }
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
        let url = URL(string: "https://google.com")!

        let clientSpy = HTTPClientSpy()
        _ = RemoteFeedLoader(url: url, client: clientSpy)

        XCTAssertNil(clientSpy.requestURL)
    }

    func testLoadRequestDataFromURL() {
        //check which url we are loading data from
        let url = URL(string: "https://yahoo.com.tw")!

        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(url: url, client: client)
        loader.load()

        XCTAssertEqual(client.requestURL, url)
    }

}
