import Foundation

struct ClientCallReq<Params:Encodable>:Encodable {
    let jsonrpc: String
    let method: String
    let params: Params?
    let id: JSONRPCID
}

struct ClientNotiReq<Params:Encodable>:Encodable {
    let jsonrpc: String
    let method: String
    let params: Params?
}

struct ServerReq<Params:Decodable>:Decodable {
    let params: Params?
}

