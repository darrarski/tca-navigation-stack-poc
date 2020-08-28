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
}

struct CounterEnvironment {
  let navigation: (NavigationStackAction) -> Void
}

let counterReducer = Reducer<CounterState, CounterAction, CounterEnvironment> { state, action, env in
  switch action {
  case .increment:
    state.count += 1
    return .none

  case .decrement:
    state.count -= 1
    return .none

  case .pushAnotherCounter:
    env.navigation(.push(CounterState(count: state.count)))
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
        }
      }.listStyle(GroupedListStyle())
    }
  }
}
