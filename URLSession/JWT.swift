//
//  JWT.swift
//  
//
//  Created by Martin Lalev on 24/05/2025.
//

import Foundation

public struct JWT: RawRepresentable, Equatable {
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public let rawValue: String
    
    private var base64Segments: [String] {
        self.rawValue.components(separatedBy: ".")
    }
    
    private func segment(at index: Int) -> [String: Any] {
        guard index < self.base64Segments.count else { return [:] }
        let base64 = self.base64Segments[index]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let bodyData = Data(base64Encoded: padded) else {
            return [:]
        }

        guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: []) else {
            return [:]
        }
        
        guard let payload = json as? [String: Any] else {
            return [:]
        }
        
        return payload
    }
    
    public var payload: [String: Any] {
        self.segment(at: 1)
    }
}
