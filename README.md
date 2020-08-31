# Navigation Stack PoC

![Swift v5.2](https://img.shields.io/badge/swift-v5.2-orange.svg)
![platforms iOS](https://img.shields.io/badge/platforms-iOS-blue.svg)

Navigation stack component for [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - **proof of concept**

## 🛠 Tech stack

- [Xcode](https://developer.apple.com/xcode/) v11.6
- [Swift](https://swift.org/) v5.2
- [iOS](https://www.apple.com/pl/ios/) v13.6
- [ComposableArchitecture](https://github.com/pointfreeco/swift-composable-architecture) v0.7.0

## 📝 Description

Proof of concept of navigation stack component that can be used along with [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) library.

`NavigationStackView` is a wrapper on `UINavigationController`. Its logic is powered by `Store` that takes `[NavigationStackItemState]` as the state. The `NavigationStackItemState` protocol should be applied to each state that represents a single screen which can be pushed onto the stack. Navigation stack updates (push, pop etc) are performed by modifying the array of stack item states in navigation stack reducer. 

Thanks to bidirectional communication between the store and `UINavigationController`, the component allows complex navigation stack manipulations (like pop-to-root or replacing already presented stack with a completely different one) that would be hard to implement with SwiftUI's `NavigationLink` views. Moreover, it fully supports navigation state restoration. Because under the hood it uses `UINavigationController`, overall user experience, navigation animations, gestures, etc. are native to iOS.

Check out included demo project that showcases a simple application containing a navigation controller and two kinds of screens. Root screen is presented as an initial screen of the app. It allows to push a counter screen. The counter screen contains simple counter label with "increment" / "decrement" buttons. It also allows to push another counter on the navigation stack or navigate back to the root of the stack.

Related resources:

- [Swift Forums - Implementing complex navigation stack in SwiftUI and The Composable Architecture](https://forums.swift.org/t/implementing-complex-navigation-stack-in-swiftui-and-the-composable-architecture/39352)


## 📄 License

Copyright © 2020 Dariusz Rybicki Darrarski

License: [GNU GPLv3](LICENSE)
