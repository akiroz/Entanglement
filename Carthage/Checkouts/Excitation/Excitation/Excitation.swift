import Foundation

// Swift type inference bug workaround
// ====================================================
// As of Swift 4.1 the compiler cannot differenciate between:
// (T) -> Void where T is Void and Void -> Void.
//
// In the case where we need to create an Event that does not
// carry data, use Emitter<None>()
//
public enum None {
    case None
}

public class Observer<T> {
    var f: ((T)->Void)?
    init(_ f: @escaping (T)->Void) {
        self.f = f
    }
    
    @objc func invoke(n: Notification) {
        if let payload = n.userInfo {
            f!(payload[0]! as! T)
        } else if self is Observer<None> {
            f!(None.None as! T)
        } else {
            let t = type(of: T.self)
            print("Excitation: Unexpected event from Emitter<\(t)> with no data.")
        }
    }
}

public class Emitter<T> {
    let nc = NotificationCenter()
    let nn = Notification.Name("ExcitationEvent")
    var obRef = [ObjectIdentifier: Observer<T>]()

    public init() {}
    
    public func emit() {
        nc.post(name: nn, object: nil)
    }
    public func emit(_ data: T) {
        nc.post(name: nn, object: nil, userInfo: [0: data])
    }
    
    public func observe(_ f: @escaping ()->Void) -> Observer<T> {
        return self.observe { (_: T) in f() }
    }
    public func observe(_ f: @escaping (T)->Void) -> Observer<T> {
        let ob = Observer<T>(f)
        nc.addObserver(
            ob, selector: #selector(ob.invoke(n:)),
            name: nn, object: nil)
        obRef[ObjectIdentifier(ob)] = ob
        return ob
    }

    public func observeAsync(_ f: @escaping ()->Void) -> Observer<T> {
        return self.observeAsync { (_: T) in f() }
    }
    public func observeAsync(_ f: @escaping (T)->Void) -> Observer<T> {
        return self.observe { data in
            DispatchQueue.main.async { f(data) }
        }
    }
    
    public func remove(_ ob: Observer<T>) {
        nc.removeObserver(ob, name: nn, object: nil)
        obRef.removeValue(forKey: ObjectIdentifier(ob))
    }
}
