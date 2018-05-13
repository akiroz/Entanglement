# Entanglement

[![Travis CI](https://travis-ci.org/akiroz/Entanglement.svg?branch=master)](https://travis-ci.org/akiroz/Entanglement)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage)
[![Swift: 4](https://img.shields.io/badge/Swift-4-orange.svg)]()
[![Platform: iOS](https://img.shields.io/badge/Platform-iOS-lightgray.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A type-checked micro-framework for working with JSON-RPC 2.0 with emphesis on minimal boilerplate code.

## Install

Carthage:

```
github "akiroz/Entanglement"
```

## Features

- [x] Send
  - [x] Call
    - [x] Cancelable
    - [x] Optional Timeout
    - [x] Custom Request ID
  - [x] Notification
  - [ ] Batch
- [x] Recieve
  - [x] Call
    - [ ] Async Handler
    - [ ] Removable Handler
  - [x] Notification
    - [ ] Removable Handler 
  - [ ] Batch

## Usage

```swift
import class Entanglement.Entanglement            // Main interface
import class Entanglement.EntRemoteCall           // Interface for canceling calls
import protocol Entanglement.EntTransportDelegate // Delegate for sending / recieving raw data

import enum Entanglement.EntServerResp            // Response data for client initiated calls
import enum Entanglement.EntClientResp            // Response data for server initiated calls
import struct Entanglement.EntErrorResp           // Generic JSON-RPC 2.0 error object

import enum Entanglement.JSONRPCID                // JSON-RPC 2.0 ID type
import enum Entanglement.JSON                     // Generic JSON data type


// Example: Sending Simple Call & Notification
// =====================================================

class MyTransport: EntTransportDelegate {
    var timeout: Int?             // In miliseconds, nil = no timeout
    var recv: ((String)->Void)?   // Handler for passing in recieved data (called by your code)
    func send(_ data: String) {   // Handler for sending data (implemented by you)
    
    }
}

// Create an entanglement instance using your data transport
let ent = Entanglement(transportDelegate: MyTransport())

// Params, Results and Errors can be any Codable types
// but the Error type must conform to the structure specified by
// the JSON-RPC 2.0 spec. You may use EntErrorResp as a generic error type.

// Call response handlers will recieve an EntServerResp enum
ent.call("myRemoteFunction") { (resp:EntServerResp<Int,EntErrorResp>) in
    switch resp {
    case let .success(result):
        assert(result == 123)
    case let .error(err):
        print(err.code, err.message, err.data ?? "nil")
    case .timeout:
        print("request timeout")
    }
}

ent.call("myRemoteFunction2", "hello", respHandler) // send function params

ent.notify("myRemoteNoti")

ent.notify("myRemoteNoti2", [1, 2, 3]) // send any Encodable data


// Example: Cancel Calls & Custom JSON-RPC IDs
// =====================================================

let myCall = ent.call("myCall") { (resp:EntServerResp<Int,EntErrorResp>) in
    // never reached
}
myCall.cancel()

// Entanglement uses random UUIDs as RPC call IDs by default
// you can provide a custom ID if you like:

ent.call("customID", id: .number(1))
ent.call("customID2", id: .string("my_id"))


// Example: Recieving Calls and Notifs
// =====================================================

// Call handlers must return the EntClientResp enum
ent.handleCall("myIncrement") { (param:Int?) -> EntClientResp<Int,EntErrorResp> in
    if let i = param {
        return .success(i+1)
    } else {
        return .error(EntErrorResp(code: -1, message: "Missing Argument"))
    }
}

ent.handleNoti("someEvent") { (_:JSON?) in
    print("someEvent happened!")
}

```


