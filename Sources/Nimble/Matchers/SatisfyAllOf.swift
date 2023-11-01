/// A Nimble matcher that succeeds when the actual value matches with all of the matchers
/// provided in the variable list of matchers.
public func satisfyAllOf<T>(_ predicates: Matcher<T>...) -> Matcher<T> {
    return satisfyAllOf(predicates)
}

/// A Nimble matcher that succeeds when the actual value matches with all of the matchers
/// provided in the array of matchers.
public func satisfyAllOf<T>(_ predicates: [Matcher<T>]) -> Matcher<T> {
    return Matcher.define { actualExpression in
        var postfixMessages = [String]()
        var status: MatcherStatus = .matches
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

        return MatcherResult(status: status, message: msg)
    }
}

public func && <T>(left: Matcher<T>, right: Matcher<T>) -> Matcher<T> {
    return satisfyAllOf(left, right)
}

#if canImport(Darwin)
import class Foundation.NSObject

extension NMBMatcher {
    @objc public class func satisfyAllOfMatcher(_ predicates: [NMBMatcher]) -> NMBMatcher {
        return NMBMatcher { actualExpression in
            if predicates.isEmpty {
                return NMBMatcherResult(
                    status: NMBMatcherStatus.fail,
                    message: NMBExpectationMessage(
                        fail: "satisfyAllOf must be called with at least one matcher"
                    )
                )
            }

            var elementEvaluators = [Matcher<NSObject>]()
            for predicate in predicates {
                let elementEvaluator = Matcher<NSObject> { expression in
                    return predicate.satisfies({ try expression.evaluate() }, location: actualExpression.location).toSwift()
                }

                elementEvaluators.append(elementEvaluator)
            }

            return try satisfyAllOf(elementEvaluators).satisfies(actualExpression).toObjectiveC()
        }
    }
}
#endif
