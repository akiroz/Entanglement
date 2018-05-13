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
- [x] Recieve
  - [x] Call
    - [ ] Async Handler
    - [ ] Removable Handler
  - [x] Notification
    - [ ] Removable Handler 

## Usage

```swift
import class Entanglement.Entanglement            // Main interface
import class Entanglement.EntRemoteCall           // Interface for canceling calls
import protocol Entanglement.EntTransportDelegate // Delegate for sending / recieving data

import enum Entanglement.EntServerResp            // Response data for client initiated calls
import enum Entanglement.EntClientResp            // Response data for server initiated calls
import struct Entanglement.EntErrorResp           // Generic JSON-RPC 2.0 error object


// Example: 
// =====================================================



```
