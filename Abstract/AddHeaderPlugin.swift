//
//  AddHeaderPlugin.swift
//  
//
//  Created by Martin Lalev on 19/05/2025.
//

public struct AddHeaderPlugin: RequestMapperPlugin {
    private let headerKey: String
    private let headerValue: @Sendable () -> String?

    public init(headerKey: String, headerValue: @Sendable @escaping () -> String?) {
        self.headerKey = headerKey
        self.headerValue = headerValue
    }
    
    public func map(_ original: Request) async throws -> Request {
        var authedHeaders: [String: String] = original.headers ?? [:]
        if let headerValue = self.headerValue() {
            authedHeaders[headerKey] = headerValue
        }

        return Request(
            original.methodName,
            host: original.host,
            path: original.path,
            query: original.query,
            body: original.body,
            headers: authedHeaders,
            timeout: original.timeout,
            cachePolicy: original.cachePolicy
        )
    }
}
