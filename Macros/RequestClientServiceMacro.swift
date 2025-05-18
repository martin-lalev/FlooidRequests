//
//  File.swift
//  
//
//  Created by Martin Lalev on 28/03/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct RequestClientServiceMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else {
            return []
        }

        let protocolName = protocolDeclaration.name.text
        
        let protocolImplementations = protocolDeclaration.memberBlock.members
            .compactMap { try? implement(declaration: $0.decl) }
        
        let clientImplementation = try StructDeclSyntax("struct \(raw: protocolName)Client: \(raw: protocolName)") {
            DeclSyntax(stringLiteral: "private let requestClient: RequestClient")
            
            try InitializerDeclSyntax("init(requestClient: RequestClient)") {
                ExprSyntax(stringLiteral: "self.requestClient = requestClient")
            }.with(\.leadingTrivia, .newlines(2))
            
            for implementedFunction in protocolImplementations {
                implementedFunction
            }
        }
        
        return [
            clientImplementation.as(DeclSyntax.self)
        ].compactMap { $0 }
    }
    
    private static func implement(declaration: DeclSyntax) throws -> FunctionDeclSyntax? {
        guard let functionDeclaration = declaration.as(FunctionDeclSyntax.self) else { return nil }
        
        guard let method = functionDeclaration.attributes.first?.as(AttributeSyntax.self)?.attributeName.description else {
            return nil
        }
        
        switch method {
        case "Get":
            return try implementEndpoint(methodArgument: ExprSyntax(".get"), declaration: functionDeclaration)
        case "Post":
            return try implementEndpoint(methodArgument: ExprSyntax(".post"), declaration: functionDeclaration)
        case "Put":
            return try implementEndpoint(methodArgument: ExprSyntax(".put"), declaration: functionDeclaration)
        case "Patch":
            return try implementEndpoint(methodArgument: ExprSyntax(".patch"), declaration: functionDeclaration)
        case "Delete":
            return try implementEndpoint(methodArgument: ExprSyntax(".delete"), declaration: functionDeclaration)
        default:
            return nil
        }
    }
}

private extension RequestClientServiceMacro {
    private static func implementEndpoint(
        methodArgument: ExprSyntax,
        declaration: FunctionDeclSyntax
    ) throws -> FunctionDeclSyntax? {
        guard let macroAttribute = declaration.attributes.first?.as(AttributeSyntax.self) else {
            return nil
        }
        guard let macroAttributeArguments = macroAttribute.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        guard let pathArgument = macroAttributeArguments.first?.expression.as(StringLiteralExprSyntax.self) else {
            return nil
        }

        return try implementEndpoint(
            methodArgument: methodArgument,
            pathArgument: pathArgument,
            declaration: declaration,
            macroAttribute: macroAttribute
        )
    }
    
    private static func implementEndpoint(
        methodArgument: ExprSyntax,
        pathArgument: StringLiteralExprSyntax,
        declaration: FunctionDeclSyntax,
        macroAttribute: AttributeSyntax
    ) throws -> FunctionDeclSyntax? {
        let path = declaration.path(from: pathArgument)
        let queryExpressions = declaration.dictionaryParameters(paramNameType: "QueryParam", variableName: "queryParams")
        let bodyExpressions = declaration.dictionaryParameters(paramNameType: "BodyParam", variableName: "bodyParams")

        let makeRequestFunctionExperession = FunctionCallExprSyntax(callee: "self.requestClient.makeRequest" as ExprSyntax) {
            LabeledExprSyntax(label: "method", expression: methodArgument)
            LabeledExprSyntax(label: "path", expression: path)
            
            if !queryExpressions.isEmpty {
                LabeledExprSyntax(label: "query", expression: ExprSyntax("queryParams"))
            }
            
            if !bodyExpressions.isEmpty {
                LabeledExprSyntax(label: "body", expression: ExprSyntax("requestClient.body(bodyParams)"))
            }

            if let timeout = macroAttribute.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "timeout" })?.expression {
                LabeledExprSyntax(label: "timeout", expression: timeout)
            }

            if let cachePolicy = macroAttribute.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "cachePolicy" })?.expression {
                LabeledExprSyntax(label: "cachePolicy", expression: cachePolicy)
            }
        }

        let functionExperession = FunctionCallExprSyntax(callee: "self.requestClient.execute" as ExprSyntax) {
            LabeledExprSyntax(label: "request", expression: ExprSyntax("request"))
        }

        let newDeclaration = declaration
            .with(\.attributes, AttributeListSyntax([]))
            .with(\.funcKeyword, declaration.funcKeyword.with(\.leadingTrivia, .newlines(2)))
            .with(\.body, CodeBlockSyntax {
                CodeBlockItemListSyntax {
                    if !queryExpressions.isEmpty {
                        DeclSyntax("var queryParams: [String: Any & Sendable] = [:]")
                        for assignment in queryExpressions {
                            assignment
                        }
                    }
                }
                
                CodeBlockItemListSyntax {
                    if !bodyExpressions.isEmpty {
                        DeclSyntax("var bodyParams: [String: Any & Sendable] = [:]")
                        for assignment in bodyExpressions {
                            assignment
                        }
                    }
                }
                
                VariableDeclSyntax(
                    bindingSpecifier: .keyword(.let),
                    bindings: PatternBindingListSyntax(itemsBuilder: {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .init(stringLiteral: "request")),
                            initializer: InitializerClauseSyntax(value: makeRequestFunctionExperession)
                        )
                    })
                )
                
                ReturnStmtSyntax(expression: ExprSyntax("try await \(functionExperession)"))
            })
        
        return newDeclaration
    }
}

extension FunctionParameterSyntax {
    var preferredName: TokenSyntax {
        self.secondName ?? self.firstName
    }
}

extension FunctionDeclSyntax {
    var allParameters: [FunctionParameterSyntax] {
        self.signature.parameterClause.parameters.map { $0 }
    }
}

extension FunctionDeclSyntax {
    func path(from pathArgument: StringLiteralExprSyntax) -> StringLiteralExprSyntax {
        pathArgument.with(\.segments, StringLiteralSegmentListSyntax {
            for segment in pathArgument.segments {
                if let stringSegment = segment.as(StringSegmentSyntax.self) {
                    let newPath = self.allParameters.reduce(stringSegment.content.text) { content, parameter in
                        content.replacingOccurrences(of: ":\(parameter.preferredName.text)", with: "\\(\(parameter.preferredName.text))")
                    }
                    StringSegmentSyntax(content: .stringSegment(newPath))
                }
            }
        })
    }
}

extension FunctionDeclSyntax {
    func dictionaryParameters(paramNameType: String, variableName: String) -> [ExprSyntax] {
        self.allParameters.compactMap { param -> ExprSyntax? in
            guard let paramType = param.type.as(IdentifierTypeSyntax.self) else {
                return nil
            }
            guard paramType.name.text == paramNameType else { return nil }
            guard let genericArgumentType = paramType.genericArgumentClause?.arguments.first?.argument else { return nil }
            
            var genericType: IdentifierTypeSyntax?
            var isOptional = false
            
            if let optionalRawType = genericArgumentType.as(OptionalTypeSyntax.self), let wrappedType = optionalRawType.wrappedType.as(IdentifierTypeSyntax.self) {
                isOptional = true
                genericType = wrappedType
            } else if let rawType = genericArgumentType.as(IdentifierTypeSyntax.self) {
                isOptional = false
                genericType = rawType
            } else {
                genericType = nil
            }
            
            guard let genericType else { return nil }

            var assignmentExpression: ExprSyntax {
                switch genericType.name.text {
                case "Date":
                    return ExprSyntax("\(raw: variableName)[\"\(raw: param.preferredName.text)\"] = \"\\(\(raw: param.preferredName.text).timeIntervalSince1970)\"")
                case "Data":
                    return ExprSyntax("\(raw: variableName)[\"\(raw: param.preferredName.text)\"] = \(raw: param.preferredName.text).base64EncodedString()")
                case "Int", "Double", "Float":
                    return ExprSyntax("\(raw: variableName)[\"\(raw: param.preferredName.text)\"] = \"\\(\(raw: param.preferredName.text))\"")
                default:
                    return ExprSyntax("\(raw: variableName)[\"\(raw: param.preferredName.text)\"] = \(raw: param.preferredName.text)")
                }
            }
            
            if isOptional {
                return ExprSyntax("if let \(raw: param.preferredName.text) { \(assignmentExpression) }")
            } else {
                return assignmentExpression
            }
        }
    }
}
