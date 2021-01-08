import ComposableArchitecture
import SwiftUI

struct RootState: NavigationStackItemState, Equatable {
  let navigationID = UUID()
  let navigationTitle = "Root"
}

enum RootAction {
  case pushCounter
}

struct RootEnvironment {}

let rootReducer = Reducer<RootState, RootAction, RootEnvironment> { state, action, env in
  switch action {
  case .pushCounter:
    return .none
  }
}

struct RootView: View {
  let store: Store<RootState, RootAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      List {
        Button(action: { viewStore.send(.pushCounter) }) {
          HStack {
            Spacer()
            Text("Push Counter")
            Spacer()
          }
        }
      }.listStyle(GroupedListStyle())
    }
  }
}

let rootViewFactory: NavigationStackItemOptionalViewFactory = { store, item in
  guard let item = item as? RootState else { return nil }
  return AnyView(IfLetStore(
    store.scope(state: { stackState -> RootState? in
      stackState.first(where: { $0.navigationID == item.navigationID }) as? RootState
    }, action: { rootAction -> NavigationStackAction<CounterStackItem> in
      NavigationStackAction.stackItemAction(action: .root(item.navigationID, rootAction))
    }),
    then: RootView.init(store:)
  ))
}
