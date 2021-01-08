//
//  CounterNavigationStack.swift
//  DemoApp
//
//  Created by Mihai Georgescu on 8/1/21.
//  Copyright © 2021 Darrarski. All rights reserved.
//

import ComposableArchitecture
import Foundation
import TCANavigationStack

enum CounterStackItem {
  case root(UUID, RootAction)
  case counter(UUID, CounterAction)
}

typealias NavigationStackReducer = Reducer<NavigationStackState, NavigationStackAction<CounterStackItem>, NavigationStackEnvironment>

let navigationStackReducer = NavigationStackReducer.combine(
  // pullback root reducer:
  NavigationStackReducer { state, action, env in
    guard case .stackItemAction(let action) = action,
          case .root(let navigationID, let rootAction) = action,
          var rootState = state.first(where: { $0.navigationID == navigationID }) as? RootState
    else { return .none }
    let rootEnvironment = RootEnvironment()
    let rootEffect = rootReducer.run(&rootState, rootAction, rootEnvironment)
    state = state.map { $0.navigationID == navigationID ? rootState : $0 }
    return rootEffect.map { NavigationStackAction<CounterStackItem>.stackItemAction(action: .root(navigationID, $0)) }
  },

  // pullback counter reducer:
  NavigationStackReducer { state, action, env in
    guard case .stackItemAction(let action) = action,
          case .counter(let navigationID, let counterAction) = action,
          var counterState = state.first(where: { $0.navigationID == navigationID }) as? CounterState
    else { return .none }
    let counterEnvironment = CounterEnvironment()
    let counterEffect = counterReducer.run(&counterState, counterAction, counterEnvironment)
    state = state.map { $0.navigationID == navigationID ? counterState : $0 }
    return counterEffect.map { NavigationStackAction<CounterStackItem>.stackItemAction(action: .counter(navigationID, $0)) }
  },

  // navigation action reducer:
  NavigationStackReducer { state, action, _ in
    switch action {
    // generic navigation actions:
    case .set(let items):
      state = items
      return .none

    case .push(let item):
      state.append(item)
      return .none

    case .pop:
      _ = state.popLast()
      return .none

    case .popToRoot:
      state = Array(state.prefix(1))
      return .none
    case .stackItemAction:
      return .none
    }
  },

  // navigation stack reducer:
  NavigationStackReducer { state, action, _ in
    guard case .stackItemAction(let action) = action else { return .none }
    switch action {
    // concrete navigation actions:
    case .root(let navigationID, .pushCounter):
      return Effect(value: .push(CounterState()))

    case .counter(let navigationID, .pushAnotherCounter):
      let counterState = state.first(where: { $0.navigationID == navigationID }) as? CounterState
      let count = counterState?.count ?? 0
      return Effect(value: .push(CounterState(count: count)))

    case .counter(let navigationID, .goToRoot):
      return Effect(value: .popToRoot)

    // unhandled stack item actions:
    case .counter:
      return .none
    }
  }
)
