import SwiftUI
import UIKit
import CloudKit
import CozyCore

/// Nhận Silent Push và lời mời `CKShare`.
final class CozyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if CloudConfig.isEnabled {
            application.registerForRemoteNotifications()
            Task { await CloudSync.shared.registerSubscriptions() }
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = CozySceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            completionHandler(.noData)
            return
        }
        Task { @MainActor in
            do {
                try await CloudSync.shared.sync()
                CozyShared.didChange()
                completionHandler(.newData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
}

final class CozySceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let metadata = connectionOptions.cloudKitShareMetadata { accept(metadata) }
    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        accept(cloudKitShareMetadata)
    }

    private func accept(_ metadata: CKShare.Metadata) {
        Task { @MainActor in
            try? await CloudSync.shared.accept(metadata)
            CozyShared.didChange()
        }
    }
}

/// Gói dữ liệu để mở bảng mời.
struct ShareInvitation: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}

/// Bảng mời chuẩn của Apple (iMessage, AirDrop, quản lý người tham gia).
struct CloudSharingView: UIViewControllerRepresentable {
    let invitation: ShareInvitation

    func makeCoordinator() -> Coordinator {
        Coordinator(title: invitation.share[CKShare.SystemFieldKey.title] as? String ?? "CozyDaily")
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: invitation.share, container: invitation.container)
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let title: String
        init(title: String) { self.title = title }

        func itemTitle(for csc: UICloudSharingController) -> String? { title }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("CKShare lỗi: \(error.localizedDescription)")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            Task { try? await CloudSync.shared.sync() }
        }
    }
}
