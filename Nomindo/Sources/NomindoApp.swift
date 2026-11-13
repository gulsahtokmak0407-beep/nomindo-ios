import SwiftUI
import UserNotifications

@main
struct NomindoApp: App {
    @StateObject private var alarmManager = AlarmManager.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    alarmManager.requestNotificationPermission()
                }
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        DispatchQueue.main.async {
            AlarmManager.shared.triggerAlarm(title: notification.request.content.body)
        }
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let body = response.notification.request.content.body
        DispatchQueue.main.async {
            AlarmManager.shared.triggerAlarm(title: body)
        }
        completionHandler()
    }
}
