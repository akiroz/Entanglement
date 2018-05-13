import XCTest
@testable import Entanglement

class EntanglementTests: XCTestCase {
    
    let idStr = "38A533FE-1079-4A82-8D99-B1C8AAAA8AC9"
    let id: JSONRPCID? = .string("38A533FE-1079-4A82-8D99-B1C8AAAA8AC9")
    
    class Transport: EntTransportDelegate {
        var timeout: EntTransportDelegate.Miliseconds?
        var sendExpectation: XCTestExpectation?
        var sendAssert: String?
        var recvHandler: ((String) -> Void)?
        func send(_ s: String) {
            if let a = sendAssert { XCTAssert(s == a) }
            if let e = sendExpectation { e.fulfill() }
        }
        func recv(_ f: @escaping (String) -> Void) {
            recvHandler = f
        }
        func inject(_ s: String) {
            recvHandler?(s)
        }
    }
    
    func serializeClientReq<T:Encodable>(
        _ method:String,
        _ params:T?,
        _ id:JSONRPCID?)
        -> String
    {
        let encoder = JSONEncoder()
        if let id = id {
            return String(
                data: try! encoder.encode(
                    ClientCallReq<T>(
                        jsonrpc: "2.0",
                        method: method,
                        params: params,
                        id: id)),
                encoding: .utf8)!
        } else {
            return String(
                data: try! encoder.encode(
                    ClientNotiReq<T>(
                        jsonrpc: "2.0",
                        method: method,
                        params: params)),
                encoding: .utf8)!
        }
    }
    
    func serializeClientResp<T,U>(
        _ id: JSONRPCID,
        _ resp:EntClientResp<T,U>)
        -> String
    {
        let encoder = JSONEncoder()
        switch resp {
        case let .success(result):
            return String(
                data: try! encoder.encode(
                    ClientSuccResp<T>(
                        jsonrpc: "2.0",
                        result: result,
                        id: id)),
                encoding: .utf8)!
        case let .error(error):
            return String(
                data: try! encoder.encode(
                    ClientErrResp<U>(
                        jsonrpc: "2.0",
                        error: error,
                        id: id)),
                encoding: .utf8)!
        }
    }

    func testClientCallSendNoParam() {
        let p: Int? = nil, t = Transport()
        t.sendExpectation = XCTestExpectation()
        t.sendAssert = serializeClientReq("foo", p, id)
        let e = Entanglement(transportDelegate: t)
        let _ = e.call("foo", p, id: id!) {(_:EntServerResp<Int,EntErrorResp>) in}
        wait(for: [t.sendExpectation!], timeout: 1)
    }
    
    func testClientCallSendWithParam() {
        let p: Int? = 123, t = Transport()
        t.sendExpectation = XCTestExpectation()
        t.sendAssert = serializeClientReq("foo", p, id)
        let e = Entanglement(transportDelegate: t)
        let _ = e.call("foo", p, id: id!) {(_:EntServerResp<Int,EntErrorResp>) in}
        wait(for: [t.sendExpectation!], timeout: 1)
    }
    
    func testClientCallRecvResult() {
        let p: Int? = nil, t = Transport()
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        let _ = e.call("foo", p, id: id!) { (resp:EntServerResp<Int,EntErrorResp>) in
            if case let .success(res) = resp {
                XCTAssert(res == 123)
                recvExpectation.fulfill()
            }
        }
        t.inject("{\"jsonrpc\":\"2.0\",\"result\":123,\"id\":\"\(idStr)\"}")
        wait(for: [recvExpectation], timeout: 1)
    }
    
    func testClientCallRecvError() {
        let p: Int? = nil, t = Transport()
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        let _ = e.call("foo", p, id: id!) { (resp:EntServerResp<Int,EntErrorResp>) in
            if case let .error(err) = resp {
                XCTAssert(err.code == 123)
                XCTAssert(err.message == "err")
                recvExpectation.fulfill()
            }
        }
        t.inject("{\"jsonrpc\":\"2.0\",\"error\":{\"code\":123,\"message\":\"err\"},\"id\":\"\(idStr)\"}")
        wait(for: [recvExpectation], timeout: 1)
    }
    
    func testClientCallRecvTimeout() {
        let p: Int? = nil, t = Transport()
        t.timeout = 20 // ms
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        let _ = e.call("foo", p, id: id!) { (resp:EntServerResp<Int,EntErrorResp>) in
            if case .timeout = resp {
                recvExpectation.fulfill()
            }
        }
        wait(for: [recvExpectation], timeout: 1)
    }
    
    func testClientCallRecvCanceled() {
        let p: Int? = nil, t = Transport()
        let e = Entanglement(transportDelegate: t)
        let c = e.call("foo", p, id: id!) { (resp:EntServerResp<Int,EntErrorResp>) in
            XCTFail()
        }
        c.cancel()
        t.inject("{\"jsonrpc\":\"2.0\",\"result\":123,\"id\":\"\(idStr)\"}")
        let noRecvExpectation = XCTestExpectation()
        let d = DispatchTime.now() + DispatchTimeInterval.milliseconds(20)
        DispatchQueue.main.asyncAfter(deadline: d) { noRecvExpectation.fulfill() }
        wait(for: [noRecvExpectation], timeout: 1)
    }
    
    func testClientNotiSend() {
        let p: Int? = nil, t = Transport()
        t.sendExpectation = XCTestExpectation()
        t.sendAssert = serializeClientReq("noti", p, nil)
        let e = Entanglement(transportDelegate: t)
        let _ = e.notify("noti", p)
        wait(for: [t.sendExpectation!], timeout: 1)
    }
    
    func testServerCallRecvNoParam() {
        let t = Transport()
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        e.handleCall("bar") { (_:Int?)->EntClientResp<Int,EntErrorResp> in
            recvExpectation.fulfill()
            return .success(0)
        }
        t.inject("{\"jsonrpc\":\"2.0\",\"method\":\"bar\",\"id\":\"\(idStr)\"}")
        wait(for: [recvExpectation], timeout: 1)
    }
    
    func testServerCallRecvWithParam() {
        let t = Transport()
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        e.handleCall("bar") { (p:Int?)->EntClientResp<Int,EntErrorResp> in
            XCTAssert(p! == 456)
            recvExpectation.fulfill()
            return .success(0)
        }
        t.inject("{\"jsonrpc\":\"2.0\",\"method\":\"bar\",\"params\":456,\"id\":\"\(idStr)\"}")
        wait(for: [recvExpectation], timeout: 1)
    }
    
    func testServerCallSendResult() {
        let t = Transport()
        let resp:EntClientResp<Int,EntErrorResp> = .success(456)
        t.sendExpectation = XCTestExpectation()
        t.sendAssert = serializeClientResp(id!, resp)
        let e = Entanglement(transportDelegate: t)
        e.handleCall("bar") { (_:Int?)->EntClientResp<Int,EntErrorResp> in resp }
        t.inject("{\"jsonrpc\":\"2.0\",\"method\":\"bar\",\"id\":\"\(idStr)\"}")
        wait(for: [t.sendExpectation!], timeout: 1)
    }
    
    func testServerCallSendError() {
        let t = Transport()
        let resp:EntClientResp<Int,EntErrorResp> =
            .error(EntErrorResp(code: 456, message: "err", data: nil))
        t.sendExpectation = XCTestExpectation()
        t.sendAssert = serializeClientResp(id!, resp)
        let e = Entanglement(transportDelegate: t)
        e.handleCall("bar") { (_:Int?)->EntClientResp<Int,EntErrorResp> in resp }
        t.inject("{\"jsonrpc\":\"2.0\",\"method\":\"bar\",\"id\":\"\(idStr)\"}")
        wait(for: [t.sendExpectation!], timeout: 1)
    }
    
    func testServerNotiRecv() {
        let t = Transport()
        let recvExpectation = XCTestExpectation()
        let e = Entanglement(transportDelegate: t)
        e.handleNoti("noti") { (p:Int?) in
            XCTAssert(p! == 456)
            recvExpectation.fulfill()
        }
        t.inject("{\"jsonrpc\":\"2.0\",\"method\":\"noti\",\"params\":456}")
        wait(for: [recvExpectation], timeout: 1)
    }
    
}
