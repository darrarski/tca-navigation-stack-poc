import ComposableArchitecture
import SwiftUI
import UIKit

typealias NavigationStackState = [NavigationStackItemState]

protocol NavigationStackItemState {
  var navigationID: UUID { get }
  var navigationTitle: String { get }
}

enum NavigationStackAction {
  case update(NavigationStackItemState)
  case set([NavigationStackItemState])
  case push(NavigationStackItemState)
  case pop
}

struct NavigationStackEnvironment {
  var navigation: (NavigationStackAction) -> Void = { _ in }
}

typealias NavigationStackReducer = Reducer<NavigationStackState, NavigationStackAction, NavigationStackEnvironment>

let navigationStackReducer = NavigationStackReducer { state, action, _ in
  switch action {
  case .update(let item):
    state = state.map { $0.navigationID == item.navigationID ? item : $0 }
    return .none

  case .set(let items):
    state = items
    return .none

  case .push(let item):
    state.append(item)
    return .none

  case .pop:
    _ = state.popLast()
    return .none
  }
}

typealias NavigationStackStore = Store<NavigationStackState, NavigationStackAction>
typealias NavigationStackViewStore = ViewStore<NavigationStackState, NavigationStackAction>
typealias NavigationStackActionDispatcher = (NavigationStackAction) -> Void
typealias NavigationStackItemViewFactory =
  (NavigationStackStore, NavigationStackItemState, NavigationStackEnvironment) -> AnyView
typealias NavigationStackItemOptionalViewFactory =
  (NavigationStackStore, NavigationStackItemState, NavigationStackEnvironment) -> AnyView?

func combine(
  _ factories: NavigationStackItemOptionalViewFactory...
) -> NavigationStackItemViewFactory {
  return { store, item, env in
    for factory in factories {
      if let view = factory(store, item, env) {
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
      rootView = viewFactory(stackStore, item, environment)
      title = item.navigationTitle
    }
  }
  let viewFactory: NavigationStackItemViewFactory
  let environment: NavigationStackEnvironment

  init(
    stackStore: NavigationStackStore,
    item: NavigationStackItemState,
    viewFactory: @escaping NavigationStackItemViewFactory,
    environment: NavigationStackEnvironment
  ) {
    self.stackStore = stackStore
    self.item = item
    self.viewFactory = viewFactory
    self.environment = environment
    super.init(rootView: viewFactory(stackStore, item, environment))
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
  private(set) var environment: NavigationStackEnvironment
  let viewFactory: NavigationStackItemViewFactory
  @ObservedObject private(set) var viewStore: NavigationStackViewStore

  init(
    store: NavigationStackStore,
    environment: NavigationStackEnvironment,
    viewFactory: @escaping NavigationStackItemViewFactory
  ) {
    self.store = store
    self.environment = environment
    self.viewFactory = viewFactory
    self.viewStore = NavigationStackViewStore(store, removeDuplicates: { lhs, rhs in
      lhs.map(\.navigationID) == rhs.map(\.navigationID) &&
        lhs.map(\.navigationTitle) == rhs.map(\.navigationTitle)
    })
    self.environment.navigation = viewStore.send(_:)
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
        viewFactory: viewFactory,
        environment: environment
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
