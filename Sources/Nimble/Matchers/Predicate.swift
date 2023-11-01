// New Matcher API
//

/// A Predicate is part of the new matcher API that provides assertions to expectations.
///
/// Given a code snippet:
///
///   expect(1).to(equal(2))
///                ^^^^^^^^
///            Called a "matcher"
///
/// A matcher consists of two parts a constructor function and the Predicate. The term Predicate
/// is used as a separate name from Matcher to help transition custom matchers to the new Nimble
/// matcher API.
///
/// The Predicate provide the heavy lifting on how to assert against a given value. Internally,
/// predicates are simple wrappers around closures to provide static type information and
/// allow composition and wrapping of existing behaviors.
public struct NimblePredicate<T> {
    fileprivate var matcher: (Expression<T>) throws -> NimblePredicateResult

    /// Constructs a predicate that knows how take a given value
    public init(_ matcher: @escaping (Expression<T>) throws -> NimblePredicateResult) {
        self.matcher = matcher
    }

    /// Uses a predicate on a given value to see if it passes the predicate.
    ///
    /// @param expression The value to run the predicate's logic against
    /// @returns A predicate result indicate passing or failing and an associated error message.
    public func satisfies(_ expression: Expression<T>) throws -> NimblePredicateResult {
        return try matcher(expression)
    }
}

/// Provides convenience helpers to defining predicates
extension NimblePredicate {
    /// Like Predicate() constructor, but automatically guard against nil (actual) values
    public static func define(matcher: @escaping (Expression<T>) throws -> NimblePredicateResult) -> NimblePredicate<T> {
        return NimblePredicate<T> { actual in
            return try matcher(actual)
        }.requireNonNil
    }

    /// Defines a predicate with a default message that can be returned in the closure
    /// Also ensures the predicate's actual value cannot pass with `nil` given.
    public static func define(_ message: String = "match", matcher: @escaping (Expression<T>, ExpectationMessage) throws -> NimblePredicateResult) -> NimblePredicate<T> {
        return NimblePredicate<T> { actual in
            return try matcher(actual, .expectedActualValueTo(message))
        }.requireNonNil
    }

    /// Defines a predicate with a default message that can be returned in the closure
    /// Unlike `define`, this allows nil values to succeed if the given closure chooses to.
    public static func defineNilable(_ message: String = "match", matcher: @escaping (Expression<T>, ExpectationMessage) throws -> NimblePredicateResult) -> NimblePredicate<T> {
        return NimblePredicate<T> { actual in
            return try matcher(actual, .expectedActualValueTo(message))
        }
    }
}

extension NimblePredicate {
    /// Provides a simple predicate definition that provides no control over the predefined
    /// error message.
    ///
    /// Also ensures the predicate's actual value cannot pass with `nil` given.
    public static func simple(_ message: String = "match", matcher: @escaping (Expression<T>) throws -> NimblePredicateStatus) -> NimblePredicate<T> {
        return NimblePredicate<T> { actual in
            return NimblePredicateResult(status: try matcher(actual), message: .expectedActualValueTo(message))
        }.requireNonNil
    }

    /// Provides a simple predicate definition that provides no control over the predefined
    /// error message.
    ///
    /// Unlike `simple`, this allows nil values to succeed if the given closure chooses to.
    public static func simpleNilable(_ message: String = "match", matcher: @escaping (Expression<T>) throws -> NimblePredicateStatus) -> NimblePredicate<T> {
        return NimblePredicate<T> { actual in
            return NimblePredicateResult(status: try matcher(actual), message: .expectedActualValueTo(message))
        }
    }
}

// The Expectation style intended for comparison to a PredicateStatus.
public enum ExpectationStyle {
    case toMatch, toNotMatch
}

/// The value that a Predicates return to describe if the given (actual) value matches the
/// predicate.
public struct NimblePredicateResult {
    /// Status indicates if the predicate matches, does not match, or fails.
    public var status: NimblePredicateStatus
    /// The error message that can be displayed if it does not match
    public var message: ExpectationMessage

    /// Constructs a new PredicateResult with a given status and error message
    public init(status: NimblePredicateStatus, message: ExpectationMessage) {
        self.status = status
        self.message = message
    }

    /// Shorthand to PredicateResult(status: PredicateStatus(bool: bool), message: message)
    public init(bool: Bool, message: ExpectationMessage) {
        self.status = NimblePredicateStatus(bool: bool)
        self.message = message
    }

    /// Converts the result to a boolean based on what the expectation intended
    public func toBoolean(expectation style: ExpectationStyle) -> Bool {
        return status.toBoolean(expectation: style)
    }
}

/// PredicateStatus is a trinary that indicates if a Predicate matches a given value or not
public enum NimblePredicateStatus {
    /// Matches indicates if the predicate / matcher passes with the given value
    ///
    /// For example, `equals(1)` returns `.matches` for `expect(1).to(equal(1))`.
    case matches
    /// DoesNotMatch indicates if the predicate / matcher fails with the given value, but *would*
    /// succeed if the expectation was inverted.
    ///
    /// For example, `equals(2)` returns `.doesNotMatch` for `expect(1).toNot(equal(2))`.
    case doesNotMatch
    /// Fail indicates the predicate will never satisfy with the given value in any case.
    /// A perfect example is that most matchers fail whenever given `nil`.
    ///
    /// Using `equal(1)` fails both `expect(nil).to(equal(1))` and `expect(nil).toNot(equal(1))`.
    /// Note: Predicate's `requireNonNil` property will also provide this feature mostly for free.
    ///       Your predicate will still need to guard against nils, but error messaging will be
    ///       handled for you.
    case fail

    /// Converts a boolean to either .matches (if true) or .doesNotMatch (if false).
    public init(bool matches: Bool) {
        if matches {
            self = .matches
        } else {
            self = .doesNotMatch
        }
    }

    private func shouldMatch() -> Bool {
        switch self {
        case .matches: return true
        case .doesNotMatch, .fail: return false
        }
    }

    private func shouldNotMatch() -> Bool {
        switch self {
        case .doesNotMatch: return true
        case .matches, .fail: return false
        }
    }

    /// Converts the PredicateStatus result to a boolean based on what the expectation intended
    internal func toBoolean(expectation style: ExpectationStyle) -> Bool {
        if style == .toMatch {
            return shouldMatch()
        } else {
            return shouldNotMatch()
        }
    }
}

extension NimblePredicate {
    /// Compatibility layer for old Matcher API, deprecated.
    /// Emulates the MatcherFunc API
    internal static func _fromDeprecatedClosure(_ matcher: @escaping (Expression<T>, FailureMessage) throws -> Bool) -> NimblePredicate {
        return NimblePredicate { actual in
            let failureMessage = FailureMessage()
            let result = try matcher(actual, failureMessage)
            return NimblePredicateResult(
                status: NimblePredicateStatus(bool: result),
                message: failureMessage.toExpectationMessage()
            )
        }
    }
}

// Backwards compatibility until Old Matcher API removal
@available(*, deprecated, message: "Use Predicate directly instead")
extension NimblePredicate: Matcher {
    /// Compatibility layer for old Matcher API, deprecated
    public static func fromDeprecatedFullClosure(_ matcher: @escaping (Expression<T>, FailureMessage, Bool) throws -> Bool) -> NimblePredicate {
        return NimblePredicate { actual in
            let failureMessage = FailureMessage()
            let result = try matcher(actual, failureMessage, true)
            return NimblePredicateResult(
                status: NimblePredicateStatus(bool: result),
                message: failureMessage.toExpectationMessage()
            )
        }
    }

    /// Compatibility layer for old Matcher API, deprecated.
    /// Emulates the MatcherFunc API
    public static func fromDeprecatedClosure(_ matcher: @escaping (Expression<T>, FailureMessage) throws -> Bool) -> NimblePredicate {
        return _fromDeprecatedClosure(matcher)
    }

    /// Compatibility layer for old Matcher API, deprecated.
    /// Same as calling .predicate on a MatcherFunc or NonNilMatcherFunc type.
    public static func fromDeprecatedMatcher<M>(_ matcher: M) -> NimblePredicate where M: Matcher, M.ValueType == T {
        return self.fromDeprecatedFullClosure(matcher.toClosure)
    }

    /// Deprecated Matcher API, use satisfies(_:_) instead
    public func matches(_ actualExpression: Expression<T>, failureMessage: FailureMessage) throws -> Bool {
        let result = try satisfies(actualExpression)
        result.message.update(failureMessage: failureMessage)
        return result.toBoolean(expectation: .toMatch)
    }

    /// Deprecated Matcher API, use satisfies(_:_) instead
    public func doesNotMatch(_ actualExpression: Expression<T>, failureMessage: FailureMessage) throws -> Bool {
        let result = try satisfies(actualExpression)
        result.message.update(failureMessage: failureMessage)
        return result.toBoolean(expectation: .toNotMatch)
    }
}

extension NimblePredicate {
    // Someday, make this public? Needs documentation
    internal func after(f: @escaping (Expression<T>, NimblePredicateResult) throws -> NimblePredicateResult) -> NimblePredicate<T> {
        // swiftlint:disable:previous identifier_name
        return NimblePredicate { actual -> NimblePredicateResult in
            let result = try self.satisfies(actual)
            return try f(actual, result)
        }
    }

    /// Returns a new Predicate based on the current one that always fails if nil is given as
    /// the actual value.
    ///
    /// This replaces `NonNilMatcherFunc`.
    public var requireNonNil: NimblePredicate<T> {
        return after { actual, result in
            if try actual.evaluate() == nil {
                return NimblePredicateResult(
                    status: .fail,
                    message: result.message.appendedBeNilHint()
                )
            }
            return result
        }
    }
}

#if canImport(Darwin)
import class Foundation.NSObject

public typealias PredicateBlock = (_ actualExpression: Expression<NSObject>) throws -> NMBPredicateResult

public class NMBPredicate: NSObject {
    private let predicate: PredicateBlock

    public init(predicate: @escaping PredicateBlock) {
        self.predicate = predicate
    }

    func satisfies(_ expression: @escaping () throws -> NSObject?, location: SourceLocation) -> NMBPredicateResult {
        let expr = Expression(expression: expression, location: location)
        do {
            return try self.predicate(expr)
        } catch let error {
            return NimblePredicateResult(status: .fail, message: .fail("unexpected error thrown: <\(error)>")).toObjectiveC()
        }
    }
}

extension NMBPredicate: NMBMatcher {
    public func matches(_ actualBlock: @escaping () -> NSObject?, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let result = satisfies(actualBlock, location: location).toSwift()
        result.message.update(failureMessage: failureMessage)
        return result.status.toBoolean(expectation: .toMatch)
    }

    public func doesNotMatch(_ actualBlock: @escaping () -> NSObject?, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let result = satisfies(actualBlock, location: location).toSwift()
        result.message.update(failureMessage: failureMessage)
        return result.status.toBoolean(expectation: .toNotMatch)
    }
}

final public class NMBPredicateResult: NSObject {
    public var status: NMBPredicateStatus
    public var message: NMBExpectationMessage

    public init(status: NMBPredicateStatus, message: NMBExpectationMessage) {
        self.status = status
        self.message = message
    }

    public init(bool success: Bool, message: NMBExpectationMessage) {
        self.status = NMBPredicateStatus.from(bool: success)
        self.message = message
    }

    public func toSwift() -> NimblePredicateResult {
        return NimblePredicateResult(status: status.toSwift(),
                               message: message.toSwift())
    }
}

extension NimblePredicateResult {
    public func toObjectiveC() -> NMBPredicateResult {
        return NMBPredicateResult(status: status.toObjectiveC(), message: message.toObjectiveC())
    }
}

final public class NMBPredicateStatus: NSObject {
    private let status: Int
    private init(status: Int) {
        self.status = status
    }

    public static let matches: NMBPredicateStatus = NMBPredicateStatus(status: 0)
    public static let doesNotMatch: NMBPredicateStatus = NMBPredicateStatus(status: 1)
    public static let fail: NMBPredicateStatus = NMBPredicateStatus(status: 2)

    public override var hash: Int { return self.status.hashValue }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherPredicate = object as? NMBPredicateStatus else {
            return false
        }
        return self.status == otherPredicate.status
    }

    public static func from(status: NimblePredicateStatus) -> NMBPredicateStatus {
        switch status {
        case .matches: return self.matches
        case .doesNotMatch: return self.doesNotMatch
        case .fail: return self.fail
        }
    }

    public static func from(bool success: Bool) -> NMBPredicateStatus {
        return self.from(status: NimblePredicateStatus(bool: success))
    }

    public func toSwift() -> NimblePredicateStatus {
        switch status {
        case NMBPredicateStatus.matches.status: return .matches
        case NMBPredicateStatus.doesNotMatch.status: return .doesNotMatch
        case NMBPredicateStatus.fail.status: return .fail
        default:
            internalError("Unhandle status for NMBPredicateStatus")
        }
    }
}

extension NimblePredicateStatus {
    public func toObjectiveC() -> NMBPredicateStatus {
        return NMBPredicateStatus.from(status: self)
    }
}

#endif
