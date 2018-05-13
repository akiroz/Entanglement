import Foundation
import Excitation

public protocol EntTransportDelegate {
    var timeout: Int? { get }
    var recv: ((String)->Void)? { get set }
    func send(_: String)
}

public class EntRemoteCall {
    let ob: Observer<(JSONRPCID,Data)>
    let e: Emitter<(JSONRPCID,Data)>
    init(_ ob:Observer<(JSONRPCID,Data)>, _ e:Emitter<(JSONRPCID,Data)>) {
        self.ob = ob
        self.e = e
    }
    public func cancel() {
        e.remove(ob)
    }
}

public class Entanglement {
    let dq = DispatchQueue.global(qos: .default)
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    let requestData = Emitter<(String,JSONRPCID?,Data)>()
    let responseData = Emitter<(JSONRPCID,Data)>()
    
    var transportDelegate: EntTransportDelegate

    struct PartialMessage:Decodable {
        let jsonrpc: String
        let method: String?
        let id: JSONRPCID?
    }
    
    public init(transportDelegate: EntTransportDelegate) {
        self.transportDelegate = transportDelegate
        
        self.transportDelegate.recv = { [unowned self] payload in
            let data = payload.data(using: .utf8)!
            guard let msg = try? self.decoder.decode(PartialMessage.self, from: data),
                msg.jsonrpc == "2.0" else {
                    print("Entanglement: recieved invalid JSON-RPC message")
                    return
            }
            if let method = msg.method {
                self.requestData.emit((method, msg.id, data))
            } else {
                if let id = msg.id {
                    self.responseData.emit((id, data))
                } else {
                    print("Entanglement: recieved invalid JSON-RPC message")
                }
            }
        }
    }
    
    public func handleCall<ReqT:Decodable,ResT:Encodable,ErrT:Decodable>(
        _ callMethod:String,
        _ f:@escaping(ReqT?)->EntClientResp<ResT,ErrT>)
    {
        let _ = requestData.observe { [unowned self] item in
            let (method, reqID, data) = item; if method == callMethod {
                guard let id = reqID else {
                    print("Entanglement: invalid call with no ID for method: \(method)")
                    return
                }
                guard let req = try? self.decoder.decode(ServerReq<ReqT>.self, from: data) else {
                    print("Entanglement: unable to decode request for method: \(method)")
                    return
                }
                self.transportDelegate.send(self.serializeClientResp(id, f(req.params)))
            }
        }
    }
    
    public func handleNoti<ReqT:Decodable>(
        _ notiMethod:String,
        _ f:@escaping(ReqT?)->Void)
    {
        let _ = requestData.observe { [unowned self] item in
            let (method, _, data) = item; if method == notiMethod {
                guard let req = try? self.decoder.decode(ServerReq<ReqT>.self, from: data) else {
                    print("Entanglement: unable to decode request for method: \(method)")
                    return
                }
                f(req.params)
            }
        }
    }
    
    public func call<ResT:Decodable,ErrT:Decodable>(
        _ method:String,
        id: JSONRPCID = .string(UUID().uuidString),
        _ f:@escaping(EntServerResp<ResT,ErrT>)->Void)
        -> EntRemoteCall
    {
        let nilParam:Int? = nil
        return call(method, nilParam, id: id, f)
    }
    public func call<ReqT:Encodable,ResT:Decodable,ErrT:Decodable>(
        _ method:String,
        _ params:ReqT?,
        id: JSONRPCID = .string(UUID().uuidString),
        _ f:@escaping(EntServerResp<ResT,ErrT>)->Void)
        -> EntRemoteCall
    {
        transportDelegate.send(serializeClientReq(method, params, id))
        var ob: Observer<(JSONRPCID,Data)>?
        ob = responseData.observe { [unowned self] item in
            let (reqID, data) = item; if reqID == id{
                self.responseData.remove(ob!)
                if let res = try? self.decoder.decode(ServerSuccResp<ResT>.self, from: data) {
                    f(.success(res.result))
                } else if let err = try? self.decoder.decode(ServerErrResp<ErrT>.self, from: data) {
                    f(.error(err.error))
                } else {
                    print("Entanglement: unable to decode response for method: \(method)")
                }
            }
        }
        if let timeout = transportDelegate.timeout {
            let dl = DispatchTime.now() + DispatchTimeInterval.milliseconds(timeout)
            dq.asyncAfter(deadline: dl) { [unowned self] in
                self.responseData.remove(ob!)
                f(.timeout)
            }
        }
        return EntRemoteCall(ob!, responseData)
    }
    
    public func notify(_ method:String) {
        let nilParam:Int? = nil
        notify(method, nilParam)
    }
    public func notify<ReqT:Encodable>(
        _ method:String,
        _ params:ReqT?)
    {
        transportDelegate.send(serializeClientReq(method, params, nil))
    }
    
    
    func serializeClientReq<T:Encodable>(
        _ method:String,
        _ params:T?,
        _ id:JSONRPCID?)
        -> String
    {
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
    
    func serializeClientResp<T,U>(_ id: JSONRPCID, _ resp:EntClientResp<T,U>) -> String {
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
}
