//
//  main.swift
//  boost-test
//
//  Created by Dan Crosby on 5/18/21.
//

import Foundation

func calcFibs(_ label: String, maxDurationSeconds: Double) {
    let startTime = Date().timeIntervalSince1970

    var a = 1
    var b = 1
    
    for i in 0..<10_000_000_000 {
        if (i % 100_000 == 0 && Date().timeIntervalSince1970 - startTime >= maxDurationSeconds) {
            break
        }
        let s = a &+ b
        a = b
        b = s
    }

    print("\(label) Did \(Date().timeIntervalSince1970 - startTime)s of work to get \(a) \(b)")
}

let backgroundQ1 = DispatchQueue(
    label: "background1", 
    qos: DispatchQoS.background, 
    attributes: DispatchQueue.Attributes(), 
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, 
    target: DispatchQueue.global())

let backgroundQ2 = DispatchQueue(
    label: "background2", 
    qos: DispatchQoS.background, 
    attributes: DispatchQueue.Attributes(), 
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, 
    target: DispatchQueue.global())

let hipriQ = DispatchQueue(
    label: "hipriQ", 
    qos: DispatchQoS.userInitiated, 
    attributes: DispatchQueue.Attributes(), 
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, 
    target: DispatchQueue.global())

let unitDuration = 1.0

// Dispatch 100 units of 1s of work to each of the background queues
for _ in 0..<100 {
        backgroundQ1.async {
            calcFibs("backgroundQ1", maxDurationSeconds: unitDuration);
        }
        backgroundQ2.async {
            calcFibs("backgroundQ2", maxDurationSeconds: unitDuration);
        }
}

// after 10s, start work on higher pri Q but synced to background Q
// This should cause the work on backgroundQ2 to all get boosted to userInitiated
let timer = Timer(timeInterval: 10, repeats: false) { timer -> Void in
    hipriQ.async {
        backgroundQ2.sync {
            calcFibs("hipriSyncedToBackground", maxDurationSeconds: unitDuration)
        }
    }
}
RunLoop.main.add(timer, forMode: RunLoop.Mode.default)

RunLoop.main.run()
