import Persist
import SwiftUI
import OverampedCore
import os.log

@main
struct OverampedApp: App {
    @PersistStorage(persister: .extensionHasBeenEnabled)
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
                                    .foregroundColor(Color(.white))
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
            .onOpenURL(perform: { url in
                Logger(subsystem: "net.yetii.Overamped", category: "URL Handler")
                    .log("Opened via URL \(url.absoluteString)")

                guard let deepLink = DeepLink(url: url) else { return }

                switch deepLink {
                case .debug:
                    showDebugView = true
                default:
                    break
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .motionShakeDidEndNotification)) { _ in
                switch DistributionMethod.current {
                case .debug, .testFlight:
                    showDebugView = true
                case .appStore, .unknown:
                    break
                }
            }
            .sheet(isPresented: $showDebugView) {
                NavigationView {
                    List {
                        Section("Installation") {
                            Button("Reset extension has been enabled") {
                                extensionHasBeenEnabled = false
                            }
                            Button("Show extension has been enabled banner") {
                                extensionHasBeenEnabled = true
                                didRecentlyInstallExtension = true
                            }
                        }

                        Section("Receipt") {
                            HStack {
                                Text("Path")
                                Spacer()
                                Text(Bundle.main.appStoreReceiptURL?.path ?? "nil")
                                    .foregroundColor(Color(.secondaryLabel))
                            }

                            HStack {
                                Text("Exists")
                                Spacer()
                                Text(
                                    Bundle
                                        .main
                                        .appStoreReceiptURL
                                        .flatMap { url in
                                            FileManager.default.fileExists(atPath: url.path).description
                                        }
                                    ?? "-"
                                )
                                    .foregroundColor(Color(.secondaryLabel))
                            }

                            HStack {
                                Text("Distribution Method")
                                Spacer()
                                Text(String(describing: DistributionMethod.current))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
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
