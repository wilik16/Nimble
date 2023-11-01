import Foundation

/// A Nimble matcher that succeeds when the actual value is an _exact_ instance of the given class.
public func beAnInstanceOf<T>(_ expectedType: T.Type) -> NimblePredicate<Any> {
    let errorMessage = "be an instance of \(String(describing: expectedType))"
    return NimblePredicate.define { actualExpression in
        let instance = try actualExpression.evaluate()
        guard let validInstance = instance else {
            return NimblePredicateResult(
                status: .doesNotMatch,
                message: .expectedActualValueTo(errorMessage)
            )
        }

        let actualString = "<\(String(describing: type(of: validInstance))) instance>"

        return NimblePredicateResult(
            status: NimblePredicateStatus(bool: type(of: validInstance) == expectedType),
            message: .expectedCustomValueTo(errorMessage, actual: actualString)
        )
    }
}

/// A Nimble matcher that succeeds when the actual value is an instance of the given class.
/// @see beAKindOf if you want to match against subclasses
public func beAnInstanceOf(_ expectedClass: AnyClass) -> NimblePredicate<NSObject> {
    let errorMessage = "be an instance of \(String(describing: expectedClass))"
    return NimblePredicate.define { actualExpression in
        let instance = try actualExpression.evaluate()
        let actualString: String
        if let validInstance = instance {
            actualString = "<\(String(describing: type(of: validInstance))) instance>"
        } else {
            actualString = "<nil>"
        }
        #if canImport(Darwin)
            let matches = instance != nil && instance!.isMember(of: expectedClass)
        #else
            let matches = instance != nil && type(of: instance!) == expectedClass
        #endif
        return NimblePredicateResult(
            status: NimblePredicateStatus(bool: matches),
            message: .expectedCustomValueTo(errorMessage, actual: actualString)
        )
    }
}

#if canImport(Darwin)
extension NMBPredicate {
    @objc public class func beAnInstanceOfMatcher(_ expected: AnyClass) -> NMBPredicate {
        return NMBPredicate { actualExpression in
            return try beAnInstanceOf(expected).satisfies(actualExpression).toObjectiveC()
        }
    }
}
#endif
