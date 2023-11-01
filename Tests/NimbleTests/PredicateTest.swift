import XCTest
import Nimble

final class PredicateTest: XCTestCase {
    func testDefineDefaultMessage() {
        failsWithErrorMessage("expected to match, got <1>") {
            expect(1).to(NimblePredicate.define { _, msg in NimblePredicateResult(status: .fail, message: msg) })
        }
    }

    func testDefineNilableDefaultMessage() {
        failsWithErrorMessage("expected to match, got <1>") {
            expect(1).to(NimblePredicate.defineNilable { _, msg in NimblePredicateResult(status: .fail, message: msg) })
        }
    }

    func testSimpleDefaultMessage() {
        failsWithErrorMessage("expected to match, got <1>") {
            expect(1).to(NimblePredicate.simple { _ in .fail })
        }
    }

    func testSimpleNilableDefaultMessage() {
        failsWithErrorMessage("expected to match, got <1>") {
            expect(1).to(NimblePredicate.simpleNilable { _ in .fail })
        }
    }
}
