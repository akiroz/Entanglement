import XCTest
@testable import Excitation

class ExcitationTests: XCTestCase {
    
    func testNoData() {
        let e = Emitter<None>()
        var pass = false
        let _ = e.observe { pass = true }
        e.emit()
        XCTAssert(pass)
    }
    
    func testWithData() {
        let e = Emitter<Int>()
        var result = 0
        let _ = e.observe { r in result = r }
        e.emit(1)
        XCTAssert(result == 1)
    }
    
    func testWithDataDiscarded() {
        let e = Emitter<Int>()
        var pass = false
        let _ = e.observe { pass = true }
        e.emit(1)
        XCTAssert(pass)
    }
    
    func testRemoveObserver() {
        let e = Emitter<None>()
        let ob = e.observe { XCTFail() }
        e.remove(ob)
        e.emit()
    }
    
    func testAsyncNoData() {
        let e = Emitter<None>()
        let ex = XCTestExpectation(description: "async event")
        let _ = e.observeAsync { ex.fulfill() }
        e.emit()
        wait(for: [ex], timeout: 1)
    }
    
    func testAsyncWithData() {
        let e = Emitter<Int>()
        let ex = XCTestExpectation(description: "async event")
        let _ = e.observeAsync { n in
            XCTAssert( n == 1 )
            ex.fulfill()
        }
        e.emit(1)
        wait(for: [ex], timeout: 1)
    }
}
