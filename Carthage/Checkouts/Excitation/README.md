# Excitation

[![Travis CI](https://travis-ci.org/akiroz/Excitation.svg?branch=master)](https://travis-ci.org/akiroz/Excitation)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A thin wrapper around `NotificationCenter` and `DispatchQueue` for supporting event-driven code.

Excitation supports both sync and async events via `DispatchQueue.main`.

## Install

Carthage:

```
github "akiroz/Excitation"
```

## Usage

```swift
import class Excitation.Emitter   // Main interface for creating events
import class Excitation.Observer  // Opaque reference for removing handlers
import enum Excitation.None       // Swift 4.1 bug workaround, see below...

// Example: Simple Event
// =====================================================

// Declare event
let e = Emitter<None>()

// Add event handler
e.observe {
  // do stuff
}

// Emit event
e.emit()

// Example: Event with Data & Async
// =====================================================

let e = Emitter<Int>()
e.observe { n in print(n) } // prints 1
e.observe { print("hi") }
e.observeAsync { print("async handler") }
e.emit(1)

// Example: Remove Handlers
// =====================================================

let e = Emitter<None>()
let ob: Observer<None> = e.observe {
    // not called
}
e.remove(ob)
e.emit()

// Example: Class Methods
// =====================================================

class MyClass {
    let evt = Emitter<None>()
    init() {
        evt.observe { [unowned self] in self.evtHandler() }
        evt.emit()
    }
    func evtHandler() {
        // do stuff
    }
}

```

## Swift 4.1 Type Inference Bug

Swift 4.1 is unable to differentiate between the following types:
- `(T) -> Void` when `T: Void`
- `Void -> Void`

As such, writing `Emitter<Void>` will result in an ambiguous polymorphic
dispatch due to the implementation details of this library.

If you need to create events that do not carry data, you could use `Emitter<None>`.
