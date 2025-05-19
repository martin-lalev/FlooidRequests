//
//  ResponseProcesser.swift
//  
//
//  Created by Martin Lalev on 19/05/2025.
//

public enum ResponseStatusCheck: Sendable {
    case all
    case single(_ code: Int)
    case list(_ codes: [Int])
    case range(_ codesRange: Range<Int>)
}

private extension Response {
    func check(_ statusCheck: ResponseStatusCheck) -> Bool {
        switch statusCheck {
        case .all:
            true
        case .single(let code):
            status == code
        case .list(let codes):
            codes.contains(status)
        case .range(let codesRange):
            codesRange.contains(status)
        }
    }
}

public final class ResponseProcesser: ResponseProcessPlugin {
    private let statusCheck: ResponseStatusCheck
    private let parse: @Sendable (Response) async throws -> ResponseProcessPluginResult
    
    public init(
        statusCheck: ResponseStatusCheck,
        parse: @Sendable @escaping (Response) async throws -> ResponseProcessPluginResult
    ) {
        self.statusCheck = statusCheck
        self.parse = parse
    }
    
    public func process(response: Response) async throws -> ResponseProcessPluginResult {
        guard response.check(statusCheck) else {
            return .notProcessed
        }
        return try await self.parse(response)
    }
}
