//
//  File.swift
//
//
//  Created by Martin Lalev on 08/01/2023.
//

import Foundation

public protocol QueryItemEncoder: Sendable {
    func queryItems(for parameters: [String: Any & Sendable]) -> [Request.QueryItem]
}

public final class RequestClient: Sendable {
    private let networkingClient: RequestExecuter
    private let requestMappers: [RequestMapperPlugin]
    private let responseProcessers: [ResponseProcessPlugin]
    private let host: String
    private let timeout: TimeInterval?
    private let cachePolicy: NSURLRequest.CachePolicy?
    private let queryItemEncoder: QueryItemEncoder
    private let decoder: JSONDecoder

    public init(
        networkingClient: RequestExecuter,
        requestMappers: [RequestMapperPlugin],
        responseProcessers: [ResponseProcessPlugin],
        host: String,
        timeout: TimeInterval?,
        cachePolicy: NSURLRequest.CachePolicy?,
        queryItemEncoder: QueryItemEncoder,
        decoder: JSONDecoder
    ) {
        self.networkingClient = networkingClient
        self.requestMappers = requestMappers
        self.responseProcessers = responseProcessers
        self.host = host
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.queryItemEncoder = queryItemEncoder
        self.decoder = decoder
    }
}

public extension RequestClient {
    func body(_ params: [String: Any & Sendable] = [:]) -> Request.Body {
        return .urlEncoded(parameters: queryItemEncoder.queryItems(for: params))
    }

    func makeRequest(
        method: Request.Method,
        path: String,
        body: Request.Body = .none,
        query: [String: Any & Sendable] = [:],
        headers:[String: String]? = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: NSURLRequest.CachePolicy? = nil
    ) -> Request {
        Request(
            method,
            host: self.host,
            path: path,
            query: queryItemEncoder.queryItems(for: query),
            body: body,
            headers: headers,
            timeout: timeout ?? self.timeout,
            cachePolicy: cachePolicy ?? self.cachePolicy
        )
    }

    func execute(request: Request) async throws -> ParsableResponse {
        return try await networkingClient.execute(
            request: request,
            requestMappers: requestMappers,
            responseProcessers: responseProcessers
        )
    }
    
    func execute<V: Codable & Sendable>(request: Request) async throws -> V {
        return try await execute(request: request).parse()
    }

    func execute(request: Request) async throws -> Data {
        return try await execute(request: request).parse()
    }

    func execute(request: Request) async throws -> Void {
        return try await execute(request: request).parse()
    }
}

public extension ParsableResponse {
    func parse<V: Codable & Sendable>() throws -> V {
        try self.decoder.decode(V.self, from: response.data)
    }

    func parse() -> Data {
        response.data
    }

    func parse() -> Void {
        ()
    }
}

@attached(peer, names: suffixed(Client))
public macro NetworkingService() = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientServiceMacro")

@attached(peer)
public macro Get(
    _ path: String,
    timeout: TimeInterval? = nil,
    cachePolicy: NSURLRequest.CachePolicy? = nil
) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientMemberMacro")

@attached(peer)
public macro Post(
    _ path: String,
    timeout: TimeInterval? = nil,
    cachePolicy: NSURLRequest.CachePolicy? = nil
) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientMemberMacro")

@attached(peer)
public macro Put(
    _ path: String,
    timeout: TimeInterval? = nil,
    cachePolicy: NSURLRequest.CachePolicy? = nil
) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientMemberMacro")

@attached(peer)
public macro Patch(
    _ path: String,
    timeout: TimeInterval? = nil,
    cachePolicy: NSURLRequest.CachePolicy? = nil
) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientMemberMacro")

@attached(peer)
public macro Delete(
    _ path: String,
    timeout: TimeInterval? = nil,
    cachePolicy: NSURLRequest.CachePolicy? = nil
) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientMemberMacro")

@freestanding(declaration, names: named(make))
public macro makeNetworkingService<T>(_ service: T.Type) = #externalMacro(module: "FlooidRequestClientMacros", type: "RequestClientFactoryMacro")

public typealias QueryParam<T> = T
public typealias BodyParam<T> = T
