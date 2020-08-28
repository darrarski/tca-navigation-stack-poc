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
      viewFactory: combine(
        rootViewFactory,
        counterViewFactory
      )
    )
  }
}
