import XCTest
import Nimble

func alwaysFail<T>() -> NimblePredicate<T> {
    return NimblePredicate { _ throws -> NimblePredicateResult in
        return NimblePredicateResult(status: .fail, message: .fail("This matcher should always fail"))
    }
}

final class AlwaysFailTest: XCTestCase {
    func testAlwaysFail() {
        failsWithErrorMessage(
            "This matcher should always fail") {
            expect(true).toNot(alwaysFail())
        }

        failsWithErrorMessage(
            "This matcher should always fail") {
            expect(true).to(alwaysFail())
        }
    }
}
