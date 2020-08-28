import ComposableArchitecture
import SwiftUI
import UIKit

public typealias NavigationStackState = [NavigationStackItemState]

public protocol NavigationStackItemState {
  var navigationID: UUID { get }
  var navigationTitle: String { get }
}

public enum NavigationStackAction {
  case update(NavigationStackItemState)
  case set([NavigationStackItemState])
  case push(NavigationStackItemState)
  case pop
}

public typealias NavigationStackReducer = Reducer<NavigationStackState, NavigationStackAction, Void>

public let navigationStackReducer = NavigationStackReducer { state, action, _ in
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

public typealias NavigationStackStore = Store<NavigationStackState, NavigationStackAction>
typealias NavigationStackViewStore = ViewStore<NavigationStackState, NavigationStackAction>
public typealias NavigationStackActionDispatcher = (NavigationStackAction) -> Void
public typealias NavigationStackItemViewFactory =
  (NavigationStackItemState, @escaping NavigationStackActionDispatcher) -> AnyView

final class NavigationStackItemViewController: UIHostingController<AnyView> {
  var item: NavigationStackItemState {
    didSet {
      rootView = viewFactory(item, navigationDispatcher)
      title = item.navigationTitle
    }
  }
  let viewFactory: NavigationStackItemViewFactory
  let navigationDispatcher: NavigationStackActionDispatcher

  init(
    item: NavigationStackItemState,
    viewFactory: @escaping NavigationStackItemViewFactory,
    navigationDispatcher: @escaping NavigationStackActionDispatcher
  ) {
    self.item = item
    self.viewFactory = viewFactory
    self.navigationDispatcher = navigationDispatcher
    super.init(rootView: viewFactory(item, navigationDispatcher))
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

public struct NavigationStackView: UIViewControllerRepresentable {
  let store: NavigationStackStore
  let viewFactory: NavigationStackItemViewFactory
  @ObservedObject private(set) var viewStore: NavigationStackViewStore

  public init(
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

  public func makeUIViewController(context: Context) -> UINavigationController {
    let navigationController = UINavigationController()
    navigationController.delegate = context.coordinator
    return navigationController
  }

  public func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
    let navigationIDs = viewStore.state.map(\.navigationID)
    let presentedViewControllers = navigationController.itemViewControllers
    let presentedNavigationIDs = presentedViewControllers.map(\.item.navigationID)
    let newViewControllers = viewStore.state.map { item -> NavigationStackItemViewController in
      let viewController = presentedViewControllers.first(where: { $0.item.navigationID == item.navigationID })
      viewController?.item = item
      return viewController ?? NavigationStackItemViewController(
        item: item,
        viewFactory: viewFactory,
        navigationDispatcher: viewStore.send(_:)
      )
    }
    guard presentedNavigationIDs != navigationIDs else { return }
    let animate = !navigationController.viewControllers.isEmpty
    navigationController.setViewControllers(newViewControllers, animated: animate)
  }

  public func makeCoordinator() -> NavigationStackCoordinator {
    NavigationStackCoordinator(view: self)
  }
}

public final class NavigationStackCoordinator: NSObject, UINavigationControllerDelegate {
  let view: NavigationStackView

  init(view: NavigationStackView) {
    self.view = view
    super.init()
  }

  public func navigationController(
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
