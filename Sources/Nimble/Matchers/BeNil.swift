/// A Nimble matcher that succeeds when the actual value is nil.
public func beNil<T>() -> NimblePredicate<T> {
    return NimblePredicate.simpleNilable("be nil") { actualExpression in
        let actualValue = try actualExpression.evaluate()
        return NimblePredicateStatus(bool: actualValue == nil)
    }
}

#if canImport(Darwin)
import Foundation

extension NMBPredicate {
    @objc public class func beNilMatcher() -> NMBPredicate {
        return NMBPredicate { actualExpression in
            return try beNil().satisfies(actualExpression).toObjectiveC()
        }
    }
}
#endif
