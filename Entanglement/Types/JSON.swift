import Foundation


public enum JSONRPCID: Equatable, Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if case let .string(id) = self { try c.encode(id); return }
        if case let .number(id) = self { try c.encode(id); return }
        try c.encodeNil()
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let id = try? c.decode(String.self) { self = .string(id); return }
        if let id = try? c.decode(Int.self) { self = .number(id); return }
        self = .null
    }
    case string(String)
    case number(Int) // Number IDs should not contain decimals
    case null
}


public enum JSON: Equatable, Codable {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if case let .bool(v) = self { try c.encode(v); return }
        if case let .string(v) = self { try c.encode(v); return }
        if case let .number(v) = self { try c.encode(v); return }
        if case let .array(v) = self { try c.encode(v); return }
        if case let .object(v) = self { try c.encode(v); return }
        try c.encodeNil()
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode([JSON].self) { self = .array(v); return }
        if let v = try? c.decode([String:JSON].self) { self = .object(v); return }
        self = .null
    }
    case bool(Bool)
    case string(String)
    case number(Double)
    case array([JSON])
    case object([String:JSON])
    case null
}
