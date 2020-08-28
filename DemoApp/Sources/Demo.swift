import ComposableArchitecture
import SwiftUI

struct DemoView: View {
  var body: some View {
    NavigationStackView(
      store: Store(
        initialState: [RootState()],
        reducer: navigationStackReducer,
        environment: ()
      ),
      viewFactory: { item, navigationStackActionDispatcher in
        switch item {
        case let item as RootState:
          return AnyView(
            RootView(store: Store(
              initialState: item,
              reducer: rootReducer.combined(with: Reducer { state, _, _ in
                navigationStackActionDispatcher(.update(state))
                return .none
              }),
              environment: RootEnvironment(
                navigation: navigationStackActionDispatcher
              )
            ))
          )

        case let item as CounterState:
          return AnyView(
            CounterView(store: Store(
              initialState: item,
              reducer: counterReducer.combined(with: Reducer { state, _, _ in
                navigationStackActionDispatcher(.update(state))
                return .none
              }),
              environment: CounterEnvironment(
                navigation: navigationStackActionDispatcher
              )
            ))
          )

        default:
          fatalError("Unknown navigation item state: <\(type(of: item))>")
        }
    })
  }
}
