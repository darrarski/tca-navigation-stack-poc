import ComposableArchitecture
import SwiftUI
import UIKit

typealias NavigationStackState = [NavigationStackItemState]

protocol NavigationStackItemState {
  var navigationID: UUID { get }
  var navigationTitle: String { get }
}

enum NavigationStackAction {
  // navigation actions:
  case set([NavigationStackItemState])
  case push(NavigationStackItemState)
  case pop
  case popToRoot
  // stack item actions:
  case root(UUID, RootAction)
  case counter(UUID, CounterAction)
}

struct NavigationStackEnvironment {}

typealias NavigationStackReducer = Reducer<NavigationStackState, NavigationStackAction, NavigationStackEnvironment>

let navigationStackReducer = NavigationStackReducer.combine(
  // pullback root reducer:
  NavigationStackReducer { state, action, env in
    guard case .root(let navigationID, let rootAction) = action,
      var rootState = state.first(where: { $0.navigationID == navigationID }) as? RootState
      else { return .none }
    let rootEnvironment = RootEnvironment()
    let rootEffect = rootReducer.run(&rootState, rootAction, rootEnvironment)
    state = state.map { $0.navigationID == navigationID ? rootState : $0 }
    return rootEffect.map { NavigationStackAction.root(navigationID, $0) }
  },

  // pullback counter reducer:
  NavigationStackReducer { state, action, env in
    guard case .counter(let navigationID, let counterAction) = action,
      var counterState = state.first(where: { $0.navigationID == navigationID }) as? CounterState
      else { return .none }
    let counterEnvironment = CounterEnvironment()
    let counterEffect = counterReducer.run(&counterState, counterAction, counterEnvironment)
    state = state.map { $0.navigationID == navigationID ? counterState : $0 }
    return counterEffect.map { NavigationStackAction.counter(navigationID, $0) }
  },

  // navigation stack reducer:
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

typealias NavigationStackStore = Store<NavigationStackState, NavigationStackAction>
typealias NavigationStackViewStore = ViewStore<NavigationStackState, NavigationStackAction>
typealias NavigationStackItemViewFactory = (NavigationStackStore, NavigationStackItemState) -> AnyView
typealias NavigationStackItemOptionalViewFactory = (NavigationStackStore, NavigationStackItemState) -> AnyView?

func combine(
  _ factories: NavigationStackItemOptionalViewFactory...
) -> NavigationStackItemViewFactory {
  return { store, item in
    for factory in factories {
      if let view = factory(store, item) {
        return view
      }
    }
    fatalError("Unknown navigation item state: <\(type(of: item))>")
  }
}

final class NavigationStackItemViewController: UIHostingController<AnyView> {
  let stackStore: NavigationStackStore
  var item: NavigationStackItemState {
    didSet {
      rootView = viewFactory(stackStore, item)
      title = item.navigationTitle
    }
  }
  let viewFactory: NavigationStackItemViewFactory

  init(
    stackStore: NavigationStackStore,
    item: NavigationStackItemState,
    viewFactory: @escaping NavigationStackItemViewFactory
  ) {
    self.stackStore = stackStore
    self.item = item
    self.viewFactory = viewFactory
    super.init(rootView: viewFactory(stackStore, item))
    title = item.navigationTitle
  }

  required init?(coder aDecoder: NSCoder) { nil }
}

extension UINavigationController {
  var itemViewControllers: [NavigationStackItemViewController] {
    get { viewControllers.compactMap { $0 as? NavigationStackItemViewController } }
    set { viewControllers = newValue }
  }
}

struct NavigationStackView: UIViewControllerRepresentable {
  let store: NavigationStackStore
  let viewFactory: NavigationStackItemViewFactory
  @ObservedObject private(set) var viewStore: NavigationStackViewStore

  init(
    store: NavigationStackStore,
    viewFactory: @escaping NavigationStackItemViewFactory
  ) {
    self.store = store
    self.viewFactory = viewFactory
    self.viewStore = NavigationStackViewStore(store, removeDuplicates: { lhs, rhs in
      lhs.map(\.navigationID) == rhs.map(\.navigationID) &&
        lhs.map(\.navigationTitle) == rhs.map(\.navigationTitle)
    })
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let navigationController = UINavigationController()
    navigationController.delegate = context.coordinator
    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
    let navigationIDs = viewStore.state.map(\.navigationID)
    let presentedViewControllers = navigationController.itemViewControllers
    let presentedNavigationIDs = presentedViewControllers.map(\.item.navigationID)
    let newViewControllers = viewStore.state.map { item -> NavigationStackItemViewController in
      let viewController = presentedViewControllers.first(where: { $0.item.navigationID == item.navigationID })
      viewController?.item = item
      return viewController ?? NavigationStackItemViewController(
        stackStore: store,
        item: item,
        viewFactory: viewFactory
      )
    }
    guard presentedNavigationIDs != navigationIDs else { return }
    let animate = !navigationController.viewControllers.isEmpty
    navigationController.setViewControllers(newViewControllers, animated: animate)
  }

  func makeCoordinator() -> NavigationStackCoordinator {
    NavigationStackCoordinator(view: self)
  }
}

final class NavigationStackCoordinator: NSObject, UINavigationControllerDelegate {
  let view: NavigationStackView

  init(view: NavigationStackView) {
    self.view = view
    super.init()
  }

  func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    let presentedViewControllers = navigationController.itemViewControllers
    let presentedNavigationItems = presentedViewControllers.map(\.item)
    let presentedNavigationIDs = presentedNavigationItems.map(\.navigationID)
    let navigationIDs = view.viewStore.state.map(\.navigationID)
    guard presentedNavigationIDs != navigationIDs else { return }
    view.viewStore.send(.set(presentedNavigationItems))
  }
}
