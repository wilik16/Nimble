/// A Nimble matcher that succeeds when the actual value matches with all of the matchers
/// provided in the variable list of matchers.
public func satisfyAllOf<T>(_ predicates: NimblePredicate<T>...) -> NimblePredicate<T> {
    return satisfyAllOf(predicates)
}

/// A Nimble matcher that succeeds when the actual value matches with all of the matchers
/// provided in the variable list of matchers.
@available(*, deprecated, message: "Use NimblePredicate instead")
public func satisfyAllOf<T, U>(_ matchers: U...) -> NimblePredicate<T>
    where U: Matcher, U.ValueType == T {
        return satisfyAllOf(matchers.map { $0.predicate })
}

/// A Nimble matcher that succeeds when the actual value matches with all of the matchers
/// provided in the array of matchers.
public func satisfyAllOf<T>(_ predicates: [NimblePredicate<T>]) -> NimblePredicate<T> {
    return NimblePredicate.define { actualExpression in
        var postfixMessages = [String]()
        var status: NimblePredicateStatus = .matches
        for predicate in predicates {
            let result = try predicate.satisfies(actualExpression)
            if result.status == .fail {
                status = .fail
            } else if result.status == .doesNotMatch, status != .fail {
                status = .doesNotMatch
            }
            postfixMessages.append("{\(result.message.expectedMessage)}")
        }

        var msg: ExpectationMessage
        if let actualValue = try actualExpression.evaluate() {
            msg = .expectedCustomValueTo(
                "match all of: " + postfixMessages.joined(separator: ", and "),
                actual: "\(actualValue)"
            )
        } else {
            msg = .expectedActualValueTo(
                "match all of: " + postfixMessages.joined(separator: ", and ")
            )
        }

        return NimblePredicateResult(status: status, message: msg)
    }
}

public func && <T>(left: NimblePredicate<T>, right: NimblePredicate<T>) -> NimblePredicate<T> {
    return satisfyAllOf(left, right)
}

#if canImport(Darwin)
import class Foundation.NSObject

extension NMBPredicate {
    @objc public class func satisfyAllOfMatcher(_ matchers: [NMBMatcher]) -> NMBPredicate {
        return NMBPredicate { actualExpression in
            if matchers.isEmpty {
                return NMBPredicateResult(
                    status: NMBPredicateStatus.fail,
                    message: NMBExpectationMessage(
                        fail: "satisfyAllOf must be called with at least one matcher"
                    )
                )
            }

            var elementEvaluators = [NimblePredicate<NSObject>]()
            for matcher in matchers {
                let elementEvaluator = NimblePredicate<NSObject> { expression in
                    if let predicate = matcher as? NMBPredicate {
                        return predicate.satisfies({ try expression.evaluate() }, location: actualExpression.location).toSwift()
                    } else {
                        let failureMessage = FailureMessage()
                        let success = matcher.matches(
                            // swiftlint:disable:next force_try
                            { try! expression.evaluate() },
                            failureMessage: failureMessage,
                            location: actualExpression.location
                        )
                        return NimblePredicateResult(bool: success, message: failureMessage.toExpectationMessage())
                    }
                }

                elementEvaluators.append(elementEvaluator)
            }

            return try satisfyAllOf(elementEvaluators).satisfies(actualExpression).toObjectiveC()
        }
    }
}
#endif
