//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 29/5/21.
//

import Foundation

public protocol HTTPClient {
    func get(form url: URL)
}

public final class RemoteFeedLoader {

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

    public func load() {
        client.get(form: url)
    }
}
