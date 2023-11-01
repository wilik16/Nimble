import Foundation

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty<S: Sequence>() -> NimblePredicate<S> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }

        var generator = actual.makeIterator()
        return NimblePredicateStatus(bool: generator.next() == nil)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty<S: SetAlgebra>() -> NimblePredicate<S> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.isEmpty)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty<S: Sequence & SetAlgebra>() -> NimblePredicate<S> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.isEmpty)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NimblePredicate<String> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.isEmpty)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For NSString instances, it is an empty string.
public func beEmpty() -> NimblePredicate<NSString> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.length == 0)
    }
}

// Without specific overrides, beEmpty() is ambiguous for NSDictionary, NSArray,
// etc, since they conform to Sequence as well as NMBCollection.

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NimblePredicate<NSDictionary> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.count == 0)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NimblePredicate<NSArray> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.count == 0)
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NimblePredicate<NMBCollection> {
    return NimblePredicate.simple("be empty") { actualExpression in
        guard let actual = try actualExpression.evaluate() else { return .fail }
        return NimblePredicateStatus(bool: actual.count == 0)
    }
}

#if canImport(Darwin)
extension NMBPredicate {
    @objc public class func beEmptyMatcher() -> NMBPredicate {
        return NMBPredicate { actualExpression in
            let location = actualExpression.location
            let actualValue = try actualExpression.evaluate()

            if let value = actualValue as? NMBCollection {
                let expr = Expression(expression: ({ value }), location: location)
                return try beEmpty().satisfies(expr).toObjectiveC()
            } else if let value = actualValue as? NSString {
                let expr = Expression(expression: ({ value }), location: location)
                return try beEmpty().satisfies(expr).toObjectiveC()
            } else if let actualValue = actualValue {
                let badTypeErrorMsg = "be empty (only works for NSArrays, NSSets, NSIndexSets, NSDictionaries, NSHashTables, and NSStrings)"
                return NMBPredicateResult(
                    status: NMBPredicateStatus.fail,
                    message: NMBExpectationMessage(
                        expectedActualValueTo: badTypeErrorMsg,
                        customActualValue: "\(String(describing: type(of: actualValue))) type"
                    )
                )
            }
            return NMBPredicateResult(
                status: NMBPredicateStatus.fail,
                message: NMBExpectationMessage(expectedActualValueTo: "be empty").appendedBeNilHint()
            )
        }
    }
}
#endif
