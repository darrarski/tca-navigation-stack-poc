import ComposableArchitecture
import SwiftUI
import UIKit

public typealias NavigationStackState = [NavigationStackItemState]

public protocol NavigationStackItemState {
  var navigationID: UUID { get }
  var navigationTitle: String { get }
}

public enum NavigationStackAction<StackItemAction> {
  // navigation actions:
  case set([NavigationStackItemState])
  case push(NavigationStackItemState)
  case pop
  case popToRoot
  // stack item actions:
  case stackItemAction(action: StackItemAction)
}

public struct NavigationStackEnvironment {
  public init() {}
}

public typealias NavigationStackStore<StackItemAction> = Store<NavigationStackState, NavigationStackAction<StackItemAction>>
typealias NavigationStackViewStore<StackItemAction> = ViewStore<NavigationStackState, NavigationStackAction<StackItemAction>>
public typealias NavigationStackItemViewFactory<StackItemAction> = (NavigationStackStore<StackItemAction>, NavigationStackItemState) -> AnyView
public typealias NavigationStackItemOptionalViewFactory<StackItemAction> = (NavigationStackStore<StackItemAction>, NavigationStackItemState) -> AnyView?

public func combine<StackItemAction>(
  _ factories: NavigationStackItemOptionalViewFactory<StackItemAction>...
) -> NavigationStackItemViewFactory<StackItemAction> {
  return { store, item in
    for factory in factories {
      if let view = factory(store, item) {
        return view
      }
    }
    fatalError("Unknown navigation item state: <\(type(of: item))>")
  }
}

public final class NavigationStackItemViewController<StackItemAction>: UIHostingController<AnyView> {
  let stackStore: NavigationStackStore<StackItemAction>
  var item: NavigationStackItemState {
    didSet {
      rootView = viewFactory(stackStore, item)
      title = item.navigationTitle
    }
  }
  let viewFactory: NavigationStackItemViewFactory<StackItemAction>

  init(
    stackStore: NavigationStackStore<StackItemAction>,
    item: NavigationStackItemState,
    viewFactory: @escaping NavigationStackItemViewFactory<StackItemAction>
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
  func itemViewControllers<StackItemAction>() -> [NavigationStackItemViewController<StackItemAction>] {
    return viewControllers.compactMap { $0 as? NavigationStackItemViewController<StackItemAction> }
  }
}

public struct NavigationStackView<StackItemAction>: UIViewControllerRepresentable {
  let store: NavigationStackStore<StackItemAction>
  let viewFactory: NavigationStackItemViewFactory<StackItemAction>
  @ObservedObject private(set) var viewStore: NavigationStackViewStore<StackItemAction>

  public init(
    store: NavigationStackStore<StackItemAction>,
    viewFactory: @escaping NavigationStackItemViewFactory<StackItemAction>
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
    let presentedViewControllers: [NavigationStackItemViewController<StackItemAction>] = navigationController.itemViewControllers()
    let presentedNavigationIDs = presentedViewControllers.map(\.item.navigationID)
    let newViewControllers = viewStore.state.map { item -> NavigationStackItemViewController<StackItemAction> in
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

  public func makeCoordinator() -> NavigationStackCoordinator<StackItemAction> {
    NavigationStackCoordinator(view: self)
  }
}

public final class NavigationStackCoordinator<StackItemAction>: NSObject, UINavigationControllerDelegate {
  let view: NavigationStackView<StackItemAction>

  init(view: NavigationStackView<StackItemAction>) {
    self.view = view
    super.init()
  }

  public func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    let presentedViewControllers: [NavigationStackItemViewController<StackItemAction>] = navigationController.itemViewControllers()
    let presentedNavigationItems = presentedViewControllers.map(\.item)
    let presentedNavigationIDs = presentedNavigationItems.map(\.navigationID)
    let navigationIDs = view.viewStore.state.map(\.navigationID)
    guard presentedNavigationIDs != navigationIDs else { return }
    view.viewStore.send(.set(presentedNavigationItems))
  }
}
