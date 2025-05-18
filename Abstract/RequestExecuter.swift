//
//  File.swift
//  
//
//  Created by Martin Lalev on 08/01/2023.
//

import Foundation

public protocol RequestExecuter: Sendable {
    func execute(request: Request) async throws -> Response
}

public protocol RequestMapperPlugin: Sendable {
    func map(_ original: Request) async throws -> Request
}

public enum ResponseProcessPluginResult: Sendable {
    case success(value: ParsableResponse)
    case retry
    case notProcessed
}

public struct ParsableResponse: Sendable {
    public let decoder: JSONDecoder
    public let response: Response
    
    public init(decoder: JSONDecoder, response: Response) {
        self.decoder = decoder
        self.response = response
    }
}
public protocol ResponseProcessPlugin: Sendable {
    func process(response: Response) async throws -> ResponseProcessPluginResult
}

public struct ResponseError: Error {
    public let response: Response
}

public extension RequestExecuter {
    func execute(
        request: Request,
        requestMappers: [RequestMapperPlugin],
        responseProcessers: [ResponseProcessPlugin]
    ) async throws -> ParsableResponse {
        if let mapper = requestMappers.first {
            return try await self.execute(
                request: mapper.map(request),
                requestMappers: Array(requestMappers.dropFirst()),
                responseProcessers: responseProcessers
            )
        } else {
            let response = try await self.execute(request: request)
            
            for (index, plugin) in responseProcessers.enumerated() {
                switch try await plugin.process(response: response) {
                case let .success(value):
                    return value
                    
                case .retry:
                    var filteredResponseProcessers = responseProcessers
                    filteredResponseProcessers.remove(at: index)
                    return try await self.execute(
                        request: request,
                        requestMappers: requestMappers,
                        responseProcessers: filteredResponseProcessers
                    )
                    
                case .notProcessed:
                    break
                }
            }
            
            throw ResponseError(response: response)
        }
    }
}
