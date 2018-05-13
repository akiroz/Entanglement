import Foundation

struct ServerSuccResp<MethodResult:Decodable>:Decodable {
    let result: MethodResult
}

struct ServerErrResp<ErrorResult:Decodable>:Decodable {
    let error: ErrorResult
}

struct ClientSuccResp<MethodResult:Encodable>:Encodable {
    let jsonrpc: String
    let result: MethodResult
    let id: JSONRPCID
}

struct ClientErrResp<ErrorResult:Encodable>:Encodable {
    let jsonrpc: String
    let error: ErrorResult
    let id: JSONRPCID
}

public struct EntErrorResp: Codable {
    let code: Int
    let message: String
    let data: JSON?
}

public enum EntServerResp<MethodResult:Decodable,ErrorResult:Decodable> {
    case success(MethodResult)
    case error(ErrorResult)
    case timeout
}

public enum EntClientResp<MethodResult:Encodable,ErrorResult:Encodable> {
    case success(MethodResult)
    case error(ErrorResult)
}
