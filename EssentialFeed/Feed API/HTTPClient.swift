//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 30/5/21.
//

import Foundation

public protocol HTTPClient {
    /// Clients are responsible to dispatch to appropriate threads, if needed
    /// - Parameter completion: The completion handler can be invoked in any thread.
    func get(from url: URL, completion: @escaping ((Result<(Data, HTTPURLResponse), Error>) -> Void))
}
