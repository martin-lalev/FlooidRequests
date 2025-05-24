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
public enum BodyItemEncoder: Sendable {
    case json, urlEncoded
}

public struct RawBodyParam: Sendable {
    public let data: Data
    public let contentType: String
    
    public init(data: Data, contentType: String) {
        self.data = data
        self.contentType = contentType
    }
}
public enum RequestExecuterServiceBody: Sendable {
    case raw(RawBodyParam)
    case params([String: Any & Sendable])
}
public protocol RequestExecuterService: Sendable {
    func makeRequest(
        method: Request.Method,
        path: String,
        body: RequestExecuterServiceBody?,
        query: [String: Any & Sendable],
        headers: [String: String]?,
        timeout: TimeInterval?,
        cachePolicy: NSURLRequest.CachePolicy?
    ) -> Request

    func execute(request: Request) async throws -> ParsableResponse
    
    func execute<V: Codable & Sendable>(request: Request) async throws -> V

    func execute(request: Request) async throws -> Data

    func execute(request: Request) async throws -> Void
}

public final class NetworkRequestExecuterClient {
    private let networkingClient: RequestExecuter
    private let requestMappers: [RequestMapperPlugin]
    private let responseProcessers: [ResponseProcessPlugin]
    private let host: String
    private let timeout: TimeInterval
    private let cachePolicy: NSURLRequest.CachePolicy
    private let queryItemEncoder: QueryItemEncoder
    private let bodyItemEncoder: BodyItemEncoder
    private let decoder: JSONDecoder

    public init(
        networkingClient: RequestExecuter,
        requestMappers: [RequestMapperPlugin],
        responseProcessers: [ResponseProcessPlugin],
        host: String,
        timeout: TimeInterval,
        cachePolicy: NSURLRequest.CachePolicy,
        queryItemEncoder: QueryItemEncoder,
        bodyItemEncoder: BodyItemEncoder,
        decoder: JSONDecoder
    ) {
        self.networkingClient = networkingClient
        self.requestMappers = requestMappers
        self.responseProcessers = responseProcessers
        self.host = host
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.queryItemEncoder = queryItemEncoder
        self.bodyItemEncoder = bodyItemEncoder
        self.decoder = decoder
    }
}

extension RequestExecuterServiceBody {
    func asRequestBody(
        bodyItemEncoder: BodyItemEncoder,
        queryItemEncoder: QueryItemEncoder
    ) -> Request.Body {
        switch (self, bodyItemEncoder) {
        case (.raw(let parameters), _):
            return .plain(data: parameters.data, contentType: parameters.contentType)
        
        case (.params(let parameters), .json):
            return .json(parameters: parameters)
        
        case (.params(let parameters), .urlEncoded):
            return .urlEncoded(parameters: queryItemEncoder.queryItems(for: parameters))
        }
    }
}

extension NetworkRequestExecuterClient: RequestExecuterService {
    public func makeRequest(
        method: Request.Method,
        path: String,
        body: RequestExecuterServiceBody?,
        query: [String: Any & Sendable],
        headers:[String: String]?,
        timeout: TimeInterval?,
        cachePolicy: NSURLRequest.CachePolicy?
    ) -> Request {
        Request(
            method,
            host: self.host,
            path: path,
            query: queryItemEncoder.queryItems(for: query),
            body: body?.asRequestBody(
                bodyItemEncoder: bodyItemEncoder,
                queryItemEncoder: queryItemEncoder
            ) ?? .none,
            headers: headers,
            timeout: timeout ?? self.timeout,
            cachePolicy: cachePolicy ?? self.cachePolicy
        )
    }

    public func execute(request: Request) async throws -> ParsableResponse {
        return try await networkingClient.execute(
            request: request,
            requestMappers: requestMappers,
            responseProcessers: responseProcessers
        )
    }
    
    public func execute<V: Codable & Sendable>(request: Request) async throws -> V {
        return try await execute(request: request).parse()
    }

    public func execute(request: Request) async throws -> Data {
        return try await execute(request: request).parse()
    }

    public func execute(request: Request) async throws -> Void {
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
public typealias HeaderParam<T> = T
public typealias BodyParam<T> = T
