#if !os(WASI)

#if canImport(Darwin) && !SWIFT_PACKAGE
import class Foundation.NSObject
import typealias Foundation.TimeInterval
import enum Dispatch.DispatchTimeInterval

private func from(objcMatcher: NMBMatcher) -> Matcher<NSObject> {
    return Matcher { actualExpression in
        let result = objcMatcher.satisfies(({ try actualExpression.evaluate() }),
                                             location: actualExpression.location)
        return result.toSwift()
    }
}

// Equivalent to Expectation, but for Nimble's Objective-C interface
public class NMBExpectation: NSObject {
    internal let _actualBlock: () -> NSObject?
    internal var _negative: Bool
    internal let _file: FileString
    internal let _line: UInt
    internal var _timeout: DispatchTimeInterval = .seconds(1)

    @objc public init(actualBlock: @escaping () -> NSObject?, negative: Bool, file: FileString, line: UInt) {
        self._actualBlock = actualBlock
        self._negative = negative
        self._file = file
        self._line = line
    }

    private var expectValue: Expectation<NSObject> {
        return expect(file: _file, line: _line, self._actualBlock() as NSObject?)
    }

    @objc public var withTimeout: (TimeInterval) -> NMBExpectation {
        return { timeout in self._timeout = timeout.dispatchInterval
            return self
        }
    }

    @objc public var to: (NMBMatcher) -> NMBExpectation {
        return { predicate in
            self.expectValue.to(from(objcMatcher: predicate))
            return self
        }
    }

    @objc public var toWithDescription: (NMBMatcher, String) -> NMBExpectation {
        return { predicate, description in
            self.expectValue.to(from(objcMatcher: predicate), description: description)
            return self
        }
    }

    @objc public var toNot: (NMBMatcher) -> NMBExpectation {
        return { predicate in
            self.expectValue.toNot(from(objcMatcher: predicate))
            return self
        }
    }

    @objc public var toNotWithDescription: (NMBMatcher, String) -> NMBExpectation {
        return { predicate, description in
            self.expectValue.toNot(from(objcMatcher: predicate), description: description)
            return self
        }
    }

    @objc public var notTo: (NMBMatcher) -> NMBExpectation { return toNot }

    @objc public var notToWithDescription: (NMBMatcher, String) -> NMBExpectation { return toNotWithDescription }

    @objc public var toEventually: (NMBMatcher) -> Void {
        return { predicate in
            self.expectValue.toEventually(
                from(objcMatcher: predicate),
                timeout: self._timeout,
                description: nil
            )
        }
    }

    @objc public var toEventuallyWithDescription: (NMBMatcher, String) -> Void {
        return { predicate, description in
            self.expectValue.toEventually(
                from(objcMatcher: predicate),
                timeout: self._timeout,
                description: description
            )
        }
    }

    @objc public var toEventuallyNot: (NMBMatcher) -> Void {
        return { predicate in
            self.expectValue.toEventuallyNot(
                from(objcMatcher: predicate),
                timeout: self._timeout,
                description: nil
            )
        }
    }

    @objc public var toEventuallyNotWithDescription: (NMBMatcher, String) -> Void {
        return { predicate, description in
            self.expectValue.toEventuallyNot(
                from(objcMatcher: predicate),
                timeout: self._timeout,
                description: description
            )
        }
    }

    @objc public var toNotEventually: (NMBMatcher) -> Void {
        return toEventuallyNot
    }

    @objc public var toNotEventuallyWithDescription: (NMBMatcher, String) -> Void {
        return toEventuallyNotWithDescription
    }

    @objc public var toNever: (NMBMatcher) -> Void {
        return { predicate in
            self.expectValue.toNever(
                from(objcMatcher: predicate),
                until: self._timeout,
                description: nil
            )
        }
    }

    @objc public var toNeverWithDescription: (NMBMatcher, String) -> Void {
        return { predicate, description in
            self.expectValue.toNever(
                from(objcMatcher: predicate),
                until: self._timeout,
                description: description
            )
        }
    }

    @objc public var neverTo: (NMBMatcher) -> Void {
        return toNever
    }

    @objc public var neverToWithDescription: (NMBMatcher, String) -> Void {
        return toNeverWithDescription
    }

    @objc public var toAlways: (NMBMatcher) -> Void {
        return { predicate in
            self.expectValue.toAlways(
                from(objcMatcher: predicate),
                until: self._timeout,
                description: nil
            )
        }
    }

    @objc public var toAlwaysWithDescription: (NMBMatcher, String) -> Void {
        return { predicate, description in
            self.expectValue.toAlways(
                from(objcMatcher: predicate),
                until: self._timeout,
                description: description
            )
        }
    }

    @objc public var alwaysTo: (NMBMatcher) -> Void {
        return toAlways
    }

    @objc public var alwaysToWithDescription: (NMBMatcher, String) -> Void {
        return toAlwaysWithDescription
    }

    @objc public class func failWithMessage(_ message: String, file: FileString, line: UInt) {
        fail(message, location: SourceLocation(file: file, line: line))
    }
}

#endif

#endif // #if !os(WASI)
