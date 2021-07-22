import Persist
import SwiftUI
import OverampedCore

@main
struct OverampedApp: App {
    @PersistStorage(
        persister: Persister(
            key: "extensionHasBeenEnabled",
            userDefaults: UserDefaults(suiteName: "group.net.yetii.overamped")!,
            defaultValue: false
        )
    )
    private(set) var extensionHasBeenEnabled: Bool

    @State
    private var didRecentlyInstallExtension = false

    @State
    private var showDebugView = false

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if extensionHasBeenEnabled {
                    VStack(spacing: 0) {
                        if didRecentlyInstallExtension {
                            HStack {
                                Text("The Overamped Safari Extension has been enabled")
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGreen))
                            Divider()
                        }
                        OverampedTabs()
                            .defaultAppStorage(UserDefaults(suiteName: "group.net.yetii.overamped")!)
                        // TODO: Pass `didRecentlyInstallExtension` via environment
                            .onChange(of: scenePhase) { scenePhase in
                                switch scenePhase {
                                case .background:
                                    didRecentlyInstallExtension = false
                                case .active, .inactive:
                                    break
                                @unknown default:
                                    break
                                }
                            }
                    }
                } else {
                    InstallationInstructionsView()
                        .onDisappear {
                            didRecentlyInstallExtension = true
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .motionShakeDidEndNotification)) { _ in
                switch DistributionMethod.current {
                case .debug, .testFlight:
                    showDebugView = true
                case .appStore:
                    break
                }
            }
            .sheet(isPresented: $showDebugView) {
                NavigationView {
                    List {
                        Button("Reset extension has been enabled") {
                            extensionHasBeenEnabled = false
                        }
                    }
                    .navigationTitle("Debug")
                }
            }
        }
    }
}

extension NSNotification.Name {
    public static let motionShakeDidEndNotification = NSNotification.Name("motionShakeDidEndNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .motionShakeDidEndNotification, object: event)
    }
}
