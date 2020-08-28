import SwiftUI
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    true
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = UIHostingController(rootView: AppView())
    window?.makeKeyAndVisible()
  }
}

struct AppView: View {
  var body: some View {
    DemoView()
  }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView()
  }
}
#endif
