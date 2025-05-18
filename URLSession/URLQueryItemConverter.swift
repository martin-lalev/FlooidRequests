//
//  URLQueryItemConverter.swift
//  DandaniaDomain
//
//  Created by Martin Lalev on 20.01.19.
//  Copyright © 2019 Martin Lalev. All rights reserved.
//

import Foundation
import FlooidRequests

public struct DefaultQueryItemEncoder: QueryItemEncoder {
    
    // MARK: - Properties
    
    let allowedCharacters: AllowedCharacters
    let arrayFormatter: ArrayFormatter
    let boolFormatter: BoolFormatter
    let dateFormatter: DateFormatter
    
    
    
    // MARK: - Initialization
    
    public init(arrayFormatter: ArrayFormatter = .brackets(indexed:false), boolFormatter: BoolFormatter = .numeric, allowedCharacters: AllowedCharacters = .latinStandard, dateFormatter: DateFormatter? = nil) {
        let defaultDateFormatter = DateFormatter()
        defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSzzz"
        
        self.arrayFormatter = arrayFormatter
        self.boolFormatter = boolFormatter
        self.allowedCharacters = allowedCharacters
        self.dateFormatter = dateFormatter ?? defaultDateFormatter
    }
    
    
    
    // MARK: - Conversions
    
    public func queryItems(for parameters: [String: Any & Sendable]) -> [Request.QueryItem] {
        return parameters.reduce([]) { (result, arg1) -> [Request.QueryItem] in
            return result + self.queryItems(for: arg1.key, value: arg1.value)
        }
    }
    
    
    
    // MARK: - Subtypes
    
    public enum ArrayFormatter: Sendable {
        case commas, brackets(indexed:Bool)
        
        func format(key: String, index: Int) -> String {
            switch self {
            case .commas:
                return key
            case .brackets(true):
                return "\(key)[\(index)]"
            case .brackets(false):
                return "\(key)[]"
            }
        }
    }
    
    public enum BoolFormatter: Sendable {
        case numeric, literal
        
        func string(from value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }
    
    public enum AllowedCharacters: Sendable {
        case broad, latinBroad, latinStandard, urlQuery
        
        func charset() -> CharacterSet {
            switch self {
            case .broad:
                return CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted
            case .latinBroad:
                var allowedCharacterSet = CharacterSet.urlQueryAllowed
                allowedCharacterSet.remove(charactersIn: "!*'();:@&=+$,/?%#[]")
                return allowedCharacterSet
            case .latinStandard:
                var allowedCharacterSet = CharacterSet.urlQueryAllowed
                allowedCharacterSet.remove(charactersIn: "!*'();:@&=+$,#[]")
                return allowedCharacterSet
            case .urlQuery:
                return CharacterSet.urlQueryAllowed
            }
        }
        
        func escape(_ string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: self.charset()) ?? string
        }
    }
    
    
    
    // MARK: - Private Implementation
    
    private func queryItems(for key: String, value: [String: Any]) -> [Request.QueryItem] {
        var result: [Request.QueryItem] = []
        for item in value {
            result += self.queryItems(for: "\(key)[\(item.key)]", value: item.value)
        }
        return result
    }
    private func queryItems(for key: String, value: [Any]) -> [Request.QueryItem] {
        var result: [Request.QueryItem] = []
        switch self.arrayFormatter {
        case .commas:
            if let stringsConvertibleArray = value as? [CustomStringConvertible] {
                let arrayString = stringsConvertibleArray.map({ self.allowedCharacters.escape($0.description) }).joined(separator: ",")
                result.append(Request.QueryItem(name: self.allowedCharacters.escape(key), value: arrayString))
            }
        case .brackets:
            for value in value.enumerated() {
                result += self.queryItems(for: arrayFormatter.format(key: key, index: value.offset), value: value.element)
            }
        }
        return result
    }
    private func queryItems(for key: String, value: Date) -> [Request.QueryItem] {
        return [Request.QueryItem(name: self.allowedCharacters.escape(key), value: self.allowedCharacters.escape(self.dateFormatter.string(from: value)))]
    }
    private func queryItems(for key: String, value: Bool) -> [Request.QueryItem] {
        return [Request.QueryItem(name: self.allowedCharacters.escape(key), value: self.allowedCharacters.escape(self.boolFormatter.string(from: value)))]
    }
    private func queryItems(for key: String, value: String) -> [Request.QueryItem] {
        return [Request.QueryItem(name: self.allowedCharacters.escape(key), value: self.allowedCharacters.escape(value))]
    }
    
    private func queryItems(for key: String, value: Any) -> [Request.QueryItem] {
        var result: [Request.QueryItem] = []
        if let dictionary = value as? [String: Any] {
            result += self.queryItems(for: key, value: dictionary)
        } else if let array = value as? [Any] {
            result += self.queryItems(for: key, value: array)
        } else if let date = value as? Date {
            result += self.queryItems(for: key, value: date)
        } else if let bool = value as? Bool {
            result += self.queryItems(for: key, value: bool)
        } else {
            result += self.queryItems(for: key, value: "\(value)")
        }
        return result
    }
    
}
