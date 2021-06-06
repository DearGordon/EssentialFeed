//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 7/6/21.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValueRepresentation: Error {}

    public func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        self.session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
        }.resume()
    }
}
