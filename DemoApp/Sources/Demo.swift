import ComposableArchitecture
import SwiftUI
import TCANavigationStack

struct DemoView: View {
  var body: some View {
    NavigationStackView(
      store: Store(
        initialState: [RootState()],
        reducer: navigationStackReducer,
        environment: NavigationStackEnvironment()
      ),
      viewFactory: combine(
        rootViewFactory,
        counterViewFactory
      )
    ).edgesIgnoringSafeArea(.all)
  }
}
