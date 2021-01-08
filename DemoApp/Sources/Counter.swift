import ComposableArchitecture
import SwiftUI

struct CounterState: NavigationStackItemState, Equatable {
  let navigationID = UUID()
  let navigationTitle = "Counter"
  var count = 0
}

enum CounterAction {
  case increment
  case decrement
  case pushAnotherCounter
  case goToRoot
}

struct CounterEnvironment {}

let counterReducer = Reducer<CounterState, CounterAction, CounterEnvironment> { state, action, env in
  switch action {
  case .increment:
    state.count += 1
    return .none

  case .decrement:
    state.count -= 1
    return .none

  case .pushAnotherCounter:
    return .none

  case .goToRoot:
    return .none
  }
}

struct CounterView: View {
  let store: Store<CounterState, CounterAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      List {
        Section {
          HStack {
            Spacer()
            Text("\(viewStore.count)")
            Spacer()
          }
        }
        Section {
          Button(action: { viewStore.send(.increment) }) {
            HStack {
              Spacer()
              Text("Increment")
              Spacer()
            }
          }
          Button(action: { viewStore.send(.decrement) }) {
            HStack {
              Spacer()
              Text("Decrement")
              Spacer()
            }
          }
        }
        Section {
          Button(action: { viewStore.send(.pushAnotherCounter) }) {
            HStack {
              Spacer()
              Text("Push Another Counter")
              Spacer()
            }
          }
          Button(action: { viewStore.send(.goToRoot) }) {
            HStack {
              Spacer()
              Text("Pop To Root")
              Spacer()
            }
          }
        }
      }.listStyle(GroupedListStyle())
    }
  }
}

let counterViewFactory: NavigationStackItemOptionalViewFactory = { store, item in
  guard let item = item as? CounterState else { return nil }
  return AnyView(IfLetStore(
    store.scope(state: { stackState -> CounterState? in
      stackState.first(where: { $0.navigationID == item.navigationID }) as? CounterState
    }, action: { counterAction -> NavigationStackAction<CounterStackItem> in
      NavigationStackAction.stackItemAction(action: .counter(item.navigationID, counterAction))
    }),
    then: CounterView.init(store:)
  ))
}
