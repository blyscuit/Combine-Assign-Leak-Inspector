//
//  ContentView.swift
//  AssignLeak
//
//  Created by Bliss on 6/12/22.
//

import Combine
import SwiftUI

struct ContentView: View {

    @State var bar: Bar? = Bar()
    @State var barNested: BarAssignOldNested? = BarAssignOldNested()
    @State var loop = 100.0

    var body: some View {
        List {
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarAssignNew())
                }
            } label: {
                Text("Assign New 💬✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarAssignOld())
                }
            } label: {
                Text("Assign Old 💬🚰")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarAssignOldNoBag())
                }
            } label: {
                Text("Assign Old No Bag 🤐✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarSink())
                }
            } label: {
                Text("Sink Weak 💬✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarSinkNoBag())
                }
            } label: {
                Text("Sink No Bag 🤐✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarSinkStrong())
                }
            } label: {
                Text("Sink Strong Self 💬🚰")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeak(bar: BarSinkOneCancel())
                }
            } label: {
                Text("Sink Single Cancellable 💬✅")
            }
            Button {
                for _ in 0...Int(loop) {

                    checkLeak(bar: BarAssignOldSingleCancelled())
                }
            } label: {
                Text("Old Single Cancelled 💬✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeakBarNested(bar: BarAssignOldNestedOutBag())
                }
            } label: {
                Text("Old Nested Self Bag 💬✅")
            }
            Button {
                for _ in 0...Int(loop) {
                    checkLeakBarNested(bar: BarAssignOldNestedInBag())
                }
            } label: {
                Text("Old Nested Output Bag 💬🚰")
            }
        }

        Slider(value: $loop, in: 1...10000, step: 1)
            .padding()
        Text(String(loop))
    }

    func checkLeak(bar: Bar) {
        self.bar = bar
        let foo = bar.$output.sink { print($0) }
        bar.input = "Hello"
        if let bar = bar as? BarCancellable {
            bar.cancel()
        }
        self.bar = nil
        foo.cancel()
    }

    func checkLeakBarNested(bar: BarAssignOldNested) {
        barNested = bar
        let foo = bar.output.$output.sink { print($0) }
        bar.input = "Hello"
        barNested = nil
        foo.cancel()
    }
}

class Bar: ObservableObject {

    @Published var input: String = ""
    @Published var output: String = ""

    deinit {
        print("\(self): \(#function)")
    }
}

class BarCancellable: Bar {

    func cancel() {}
}

/// The way it meant to be used
class BarAssignOldNested: ObservableObject {

    final class Output: ObservableObject {

        @Published var output: String = ""

        // Should NOT declare here in what so ever way, declared for example purpose
        var subscription = Set<AnyCancellable>()

        deinit {
            print("\(self): \(#function)")
        }
    }

    @Published var input: String = ""
    @Published var output = Output()

    deinit {
        print("\(self): \(#function)")
    }
}

final class BarSink: Bar {

    private var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .sink { [weak self] input in
                self?.output = input
            }
            .store(in: &subscription)
    }
}

final class BarSinkStrong: Bar {

    private var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .sink { input in
                self.output = input
            }
            .store(in: &subscription)
    }
}

final class BarSinkOneCancel: Bar {

    private var subscription: Cancellable?

    override init() {
        super.init()
        subscription = $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .sink { [weak self] input in
                self?.output = input
            }
    }
}

final class BarSinkNoBag: Bar {

    override init() {
        super.init()
        _ = $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .sink { [weak self] input in
                self?.output = input
            }
    }
}

final class BarAssignOld: Bar {

    private var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: self)
            .store(in: &subscription)
    }
}

final class BarAssignOldCancelled: BarCancellable {

    private var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: self)
            .store(in: &subscription)
    }

    override func cancel() {
        subscription.removeAll()
    }
}

final class BarAssignOldSingleCancelled: BarCancellable {

    private var subscription: AnyCancellable?

    override init() {
        super.init()
        subscription = $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: self)
    }

    override func cancel() {
        subscription?.cancel()
    }
}

/// The way it meant to be used
final class BarAssignOldNestedOutBag: BarAssignOldNested {

    var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: output)
            .store(in: &subscription)
    }

    deinit {
        print("\(self): \(#function)")
    }
}

final class BarAssignOldNestedInBag: BarAssignOldNested {

    var subscription = Set<AnyCancellable>()

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: output)
            .store(in: &output.subscription)
    }

    deinit {
        print("\(self): \(#function)")
    }
}

final class BarAssignOldNoBag: Bar {

    override init() {
        super.init()
        _ = $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: \.output, on: self)
    }
}

final class BarAssignNew: Bar {

    override init() {
        super.init()
        $input
            .filter { $0.count > 0 }
            .map { "\($0) World!" }
            .assign(to: &$output)
    }
}
