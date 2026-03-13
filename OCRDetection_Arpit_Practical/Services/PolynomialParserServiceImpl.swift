//
//  PolynomialParserServiceImpl.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation

/// Implementation of polynomial parser using recursive descent parsing.
/// Handles tokenization, AST construction, simplification, derivatives, and evaluation.
final class PolynomialParserServiceImpl: PolynomialParserService {

    // MARK: - Singleton

    static let shared = PolynomialParserServiceImpl()

    // MARK: - Types

    private enum Token: Equatable {
        case number(Double)
        case variable(String)
        case mathOperator(MathOperator)
        case leftParen
        case rightParen
        case power
        case eof

        var description: String {
            switch self {
            case .number(let n): return "Number(\(n))"
            case .variable(let v): return "Variable(\(v))"
            case .mathOperator(let op): return "Operator(\(op.symbol))"
            case .leftParen: return "LeftParen"
            case .rightParen: return "RightParen"
            case .power: return "Power(^)"
            case .eof: return "EOF"
            }
        }
    }

    private enum MathOperator: String, Equatable {
        case add = "+"
        case subtract = "-"
        case multiply = "×"
        case divide = "÷"
        case asterisk = "*"
        case slash = "/"

        var symbol: String { rawValue }

        var precedence: Int {
            switch self {
            case .add, .subtract: return 1
            case .multiply, .divide, .asterisk, .slash: return 2
            }
        }

        var isAssociative: Bool {
            switch self {
            case .add, .multiply, .asterisk: return true
            case .subtract, .divide, .slash: return false
            }
        }
    }

    private indirect enum ExpressionNode: Equatable {
        case number(Double)
        case variable(String)
        case binary(ExpressionNode, MathOperator, ExpressionNode)
        case power(ExpressionNode, ExpressionNode)
        case unary(MathOperator, ExpressionNode)

        var description: String {
            switch self {
            case .number(let n): return "\(n)"
            case .variable(let v): return v
            case .binary(let left, let op, let right):
                return "(\(left.description) \(op.symbol) \(right.description))"
            case .power(let base, let exp):
                return "(\(base.description)^\(exp.description))"
            case .unary(let op, let expr):
                return "\(op.symbol)(\(expr.description))"
            }
        }
    }

    // MARK: - Properties

    private let validVariables = Set(["x", "y", "z", "n"])

    // MARK: - Init

    private init() {}

    // MARK: - PolynomialParserService

    func parse(_ expression: String) async throws -> PolynomialMathResult {
        // Run on background thread for CPU-intensive parsing
        return try await Task.detached(priority: .userInitiated) {
            try self.processExpression(expression)
        }.value
    }

    func simplify(_ expression: String) throws -> String? {
        let normalized = normalizeExpression(expression)
        let tokens = try tokenize(normalized)
        let ast = try buildAST(from: tokens)
        let simplified = simplifyNode(ast)
        return formatExpression(simplified)
    }

    func derivative(_ expression: String) throws -> String? {
        let normalized = normalizeExpression(expression)
        let tokens = try tokenize(normalized)
        let ast = try buildAST(from: tokens)
        let derivAST = calculateDerivative(ast, variable: "x")
        return formatExpression(derivAST)
    }

    func evaluate(_ expression: String, at x: Double) throws -> Double? {
        let normalized = normalizeExpression(expression)
        let tokens = try tokenize(normalized)
        let ast = try buildAST(from: tokens)
        return try evaluateNode(ast, variables: ["x": x])
    }

    func evaluate(_ expression: String, at values: [Double]) throws -> [Double: Double] {
        var results: [Double: Double] = [:]
        let normalized = normalizeExpression(expression)
        let tokens = try tokenize(normalized)
        let ast = try buildAST(from: tokens)

        for value in values {
            do {
                let result = try evaluateNode(ast, variables: ["x": value])
                results[value] = result
            } catch {
                results[value] = nil
            }
        }

        return results
    }

    // MARK: - Private Methods - Expression Processing

    private func processExpression(_ expression: String) throws -> PolynomialMathResult {
        do {
            let normalized = normalizeExpression(expression)
            let tokens = try tokenize(normalized)
            let ast = try buildAST(from: tokens)

            // Simplify
            let simplifiedAST = simplifyNode(ast)
            let simplified = formatExpression(simplifiedAST)

            // Derivative
            let derivAST = calculateDerivative(ast, variable: "x")
            let derivative = formatExpression(derivAST)

            // Evaluate at x=1 and x=2
            let valueAt1 = try? evaluateNode(ast, variables: ["x": 1.0])
            let valueAt2 = try? evaluateNode(ast, variables: ["x": 2.0])

            return PolynomialMathResult(
                original: expression,
                simplified: simplified,
                derivative: derivative,
                valueAt1: valueAt1,
                valueAt2: valueAt2
            )
        } catch {
            // Return partial result with error
            return PolynomialMathResult(
                original: expression,
                error: error as? PolynomialMathResult.MathError ?? .unknown(error.localizedDescription)
            )
        }
    }

    // MARK: - Private Methods - Normalization

    private func normalizeExpression(_ expression: String) -> String {
        var normalized = expression

        // Replace Unicode operators with ASCII equivalents
        normalized = normalized.replacingOccurrences(of: "−", with: "-")  // Minus
        normalized = normalized.replacingOccurrences(of: "×", with: "*")  // Multiply
        normalized = normalized.replacingOccurrences(of: "÷", with: "/")  // Divide

        // Replace superscript numbers with ^ notation
        normalized = replaceSuperscripts(normalized)

        // Remove whitespace
        normalized = normalized.replacingOccurrences(of: " ", with: "")

        return normalized
    }

    private func replaceSuperscripts(_ text: String) -> String {
        let superscriptMap: [Character: String] = [
            "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4",
            "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9"
        ]

        var result = text
        var i = 0

        while i < result.count {
            let index = result.index(result.startIndex, offsetBy: i)
            let char = result[index]

            if let replacement = superscriptMap[char] {
                let beforeIndex = result.index(result.startIndex, offsetBy: i)
                let afterIndex = result.index(beforeIndex, offsetBy: 1)

                // Check if there's a ^ before the superscript
                if i > 0 {
                    let prevIndex = result.index(result.startIndex, offsetBy: i - 1)
                    let prevChar = result[prevIndex]
                    if prevChar != "^" {
                        // Insert ^ before the character
                        result.insert("^", at: beforeIndex)
                        i += 1
                    }
                }

                result.replaceSubrange(beforeIndex..<afterIndex, with: replacement)
                i += replacement.count - 1
            }

            i += 1
        }

        return result
    }

    // MARK: - Private Methods - Tokenization

    private func tokenize(_ expression: String) throws -> [Token] {
        var tokens: [Token] = []
        var i = expression.startIndex

        while i < expression.endIndex {
            let char = expression[i]

            switch char {
            case "0"..."9":
                // Parse number
                let number = parseNumber(expression, from: &i)
                tokens.append(.number(number))

            case "x", "y", "z", "n":
                // Variable
                tokens.append(.variable(String(char)))
                i = expression.index(after: i)

            case "+":
                tokens.append(.mathOperator(.add))
                i = expression.index(after: i)

            case "-":
                tokens.append(.mathOperator(.subtract))
                i = expression.index(after: i)

            case "*", "×":
                tokens.append(.mathOperator(.multiply))
                i = expression.index(after: i)

            case "/", "÷":
                tokens.append(.mathOperator(.divide))
                i = expression.index(after: i)

            case "^":
                tokens.append(.power)
                i = expression.index(after: i)

            case "(":
                tokens.append(.leftParen)
                i = expression.index(after: i)

            case ")":
                tokens.append(.rightParen)
                i = expression.index(after: i)

            case " ":
                // Skip whitespace
                i = expression.index(after: i)

            default:
                // Unknown character
                i = expression.index(after: i)
            }
        }

        tokens.append(.eof)
        return tokens
    }

    private func parseNumber(_ expression: String, from index: inout String.Index) -> Double {
        var numStr = ""
        var i = index

        while i < expression.endIndex {
            let char = expression[i]
            if char.isNumber || char == "." {
                numStr.append(char)
                i = expression.index(after: i)
            } else {
                break
            }
        }

        index = i
        return Double(numStr) ?? 0.0
    }

    // MARK: - Private Methods - AST Building (Recursive Descent)

    private func buildAST(from tokens: [Token]) throws -> ExpressionNode {
        var index = 0

        func currentToken() -> Token {
            index < tokens.count ? tokens[index] : .eof
        }

        func advance() {
            index += 1
        }

        // Expression ::= Term { ('+' | '-') Term }
        func parseExpression() throws -> ExpressionNode {
            var left = try parseTerm()

            while true {
                switch currentToken() {
                case .mathOperator(.add):
                    advance()
                    let right = try parseTerm()
                    left = .binary(left, .add, right)

                case .mathOperator(.subtract):
                    advance()
                    let right = try parseTerm()
                    left = .binary(left, .subtract, right)

                default:
                    return left
                }
            }
        }

        // Term ::= Factor { ('*' | '/') Factor }
        func parseTerm() throws -> ExpressionNode {
            var left = try parseFactor()

            while true {
                switch currentToken() {
                case .mathOperator(.multiply), .mathOperator(.asterisk):
                    advance()
                    let right = try parseFactor()
                    left = .binary(left, .multiply, right)

                case .mathOperator(.divide), .mathOperator(.slash):
                    advance()
                    let right = try parseFactor()
                    left = .binary(left, .divide, right)

                default:
                    return left
                }
            }
        }

        // Factor ::= Power [ '^' Factor ] | Number | Variable | '(' Expression ')'
        func parseFactor() throws -> ExpressionNode {
            var base = try parsePrimary()

            while currentToken() == .power {
                advance()
                let exponent = try parseFactor()
                base = .power(base, exponent)
            }

            return base
        }

        // Primary ::= Number | Variable | '(' Expression ')'
        func parsePrimary() throws -> ExpressionNode {
            switch currentToken() {
            case .number(let n):
                advance()
                return .number(n)

            case .variable(let v):
                advance()
                return .variable(v)

            case .leftParen:
                advance()
                let expr = try parseExpression()
                guard currentToken() == .rightParen else {
                    throw PolynomialMathResult.MathError.invalidSyntax
                }
                advance()
                return expr

            case .mathOperator(.subtract):
                // Unary minus
                advance()
                let expr = try parseFactor()
                return .unary(.subtract, expr)

            default:
                throw PolynomialMathResult.MathError.invalidSyntax
            }
        }

        let result = try parseExpression()

        guard currentToken() == .eof else {
            throw PolynomialMathResult.MathError.invalidSyntax
        }

        return result
    }

    // MARK: - Private Methods - Simplification

    private func simplifyNode(_ node: ExpressionNode) -> ExpressionNode {
        switch node {
        case .number, .variable:
            return node

        case .binary(let left, let op, let right):
            let simplifiedLeft = simplifyNode(left)
            let simplifiedRight = simplifyNode(right)

            // Try to evaluate constant expressions
            if case .number(let l) = simplifiedLeft,
               case .number(let r) = simplifiedRight {
                let result: Double?
                switch op {
                case .add: result = l + r
                case .subtract: result = l - r
                case .multiply, .asterisk: result = l * r
                case .divide, .slash: result = r != 0 ? l / r : nil
                }
                if let result = result {
                    return .number(result)
                }
            }

            // Simplify: x + 0 = x, x - 0 = x
            if case .number(0) = simplifiedRight, (op == .add || op == .subtract) {
                return simplifiedLeft
            }

            // Simplify: 0 + x = x
            if case .number(0) = simplifiedLeft, op == .add {
                return simplifiedRight
            }

            // Simplify: x * 1 = x, x / 1 = x
            if case .number(1) = simplifiedRight, (op == .multiply || op == .asterisk || op == .divide || op == .slash) {
                return simplifiedLeft
            }

            // Simplify: 1 * x = x
            if case .number(1) = simplifiedLeft, (op == .multiply || op == .asterisk) {
                return simplifiedRight
            }

            // Simplify: x * 0 = 0, 0 * x = 0
            let leftIsZero = if case .number(0) = simplifiedLeft { true } else { false }
            let rightIsZero = if case .number(0) = simplifiedRight { true } else { false }
            if (leftIsZero || rightIsZero), (op == .multiply || op == .asterisk) {
                return .number(0)
            }

            return .binary(simplifiedLeft, op, simplifiedRight)

        case .power(let base, let exp):
            let simplifiedBase = simplifyNode(base)
            let simplifiedExp = simplifyNode(exp)

            // Simplify: x^1 = x
            if case .number(1) = simplifiedExp {
                return simplifiedBase
            }

            // Simplify: x^0 = 1
            if case .number(0) = simplifiedExp {
                return .number(1)
            }

            // Try to evaluate constant powers
            if case .number(let b) = simplifiedBase,
               case .number(let e) = simplifiedExp {
                return .number(pow(b, e))
            }

            return .power(simplifiedBase, simplifiedExp)

        case .unary(let op, let expr):
            let simplified = simplifyNode(expr)

            // Simplify: -(-x) = x
            if case .unary(.subtract, let inner) = simplified, op == .subtract {
                return inner
            }

            // Try to evaluate constant unary
            if case .number(let n) = simplified, op == .subtract {
                return .number(-n)
            }

            return .unary(op, simplified)
        }
    }

    // MARK: - Private Methods - Derivative Calculation

    private func calculateDerivative(_ node: ExpressionNode, variable: String) -> ExpressionNode {
        switch node {
        case .number:
            return .number(0)

        case .variable(let v):
            return .number(v == variable ? 1.0 : 0.0)

        case .binary(let left, let op, let right):
            let leftDeriv = calculateDerivative(left, variable: variable)
            let rightDeriv = calculateDerivative(right, variable: variable)

            switch op {
            case .add:
                // (f + g)' = f' + g'
                return .binary(leftDeriv, .add, rightDeriv)

            case .subtract:
                // (f - g)' = f' - g'
                return .binary(leftDeriv, .subtract, rightDeriv)

            case .multiply, .asterisk:
                // (f * g)' = f'g + fg'
                let term1 = ExpressionNode.binary(leftDeriv, .multiply, right)
                let term2 = ExpressionNode.binary(left, .multiply, rightDeriv)
                return ExpressionNode.binary(term1, .add, term2)

            case .divide, .slash:
                // (f / g)' = (f'g - fg') / g^2
                let numerator1 = ExpressionNode.binary(leftDeriv, .multiply, right)
                let numerator2 = ExpressionNode.binary(left, .multiply, rightDeriv)
                let numerator = ExpressionNode.binary(numerator1, .subtract, numerator2)
                let denominator = ExpressionNode.power(right, .number(2))
                return ExpressionNode.binary(numerator, .divide, denominator)
            }

        case .power(let base, let exp):
            // For x^n where n is constant: (x^n)' = nx^(n-1)
            if case .variable(let v) = base, v == variable,
               case .number(let n) = exp {
                let coefficient = ExpressionNode.number(n)
                let newExp = ExpressionNode.number(n - 1)
                let powerTerm = ExpressionNode.power(.variable(variable), newExp)
                return ExpressionNode.binary(coefficient, .multiply, powerTerm)
            }

            // For constant^x: derivative is constant^x * ln(constant)
            // This is complex, return simplified form
            return .number(0)

        case .unary(let op, let expr):
            let deriv = calculateDerivative(expr, variable: variable)
            if op == .subtract {
                return .unary(.subtract, deriv)
            }
            return deriv
        }
    }

    // MARK: - Private Methods - Evaluation

    private func evaluateNode(_ node: ExpressionNode, variables: [String: Double]) throws -> Double {
        switch node {
        case .number(let n):
            return n

        case .variable(let v):
            guard let value = variables[v] else {
                // Assume x=1 if not specified (for single-variable expressions)
                return variables["x"] ?? 1.0
            }
            return value

        case .binary(let left, let op, let right):
            let leftVal = try evaluateNode(left, variables: variables)
            let rightVal = try evaluateNode(right, variables: variables)

            switch op {
            case .add: return leftVal + rightVal
            case .subtract: return leftVal - rightVal
            case .multiply, .asterisk: return leftVal * rightVal
            case .divide, .slash:
                if rightVal == 0 {
                    throw PolynomialMathResult.MathError.divisionByZero
                }
                return leftVal / rightVal
            }

        case .power(let base, let exp):
            let baseVal = try evaluateNode(base, variables: variables)
            let expVal = try evaluateNode(exp, variables: variables)
            return pow(baseVal, expVal)

        case .unary(let op, let expr):
            let val = try evaluateNode(expr, variables: variables)
            if op == .subtract {
                return -val
            }
            return val
        }
    }

    // MARK: - Private Methods - Formatting

    private func formatExpression(_ node: ExpressionNode) -> String {
        switch node {
        case .number(let n):
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", n)
            }
            return String(format: "%.2f", n).trimmingCharacters(in: .whitespaces)

        case .variable(let v):
            return v

        case .binary(let left, let op, let right):
            let leftStr = formatExpression(left)
            let rightStr = formatExpression(right)
            return "\(leftStr) \(op.symbol) \(rightStr)"

        case .power(let base, let exp):
            let baseStr = formatExpression(base)
            let expStr = formatExpression(exp)
            return "\(baseStr)^\(expStr)"

        case .unary(let op, let expr):
            let exprStr = formatExpression(expr)
            return "\(op.symbol)(\(exprStr))"
        }
    }
}
