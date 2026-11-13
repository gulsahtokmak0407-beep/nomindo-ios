import Foundation
import SwiftUI
import UserNotifications

struct WorkoutAlarm: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int
    var label: String
    var isEnabled: Bool = true

    var formattedTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

final class AlarmManager: ObservableObject {
    static let shared = AlarmManager()

    @Published var alarms: [WorkoutAlarm] = [] {
        didSet { saveAlarms() }
    }
    @Published var streakCount: Int {
        didSet { UserDefaults.standard.set(streakCount, forKey: "nomindo_streak") }
    }
    @Published var isAlarmRinging: Bool = false
    @Published var activeAlarmLabel: String = "SPOR VAKTİ!"
    @Published var dismissAttemptCount: Int = 0
    @Published var currentPressureMessage: String = "IT'S TIME TO DO IT!"

    let pressureMessages: [String] = [
        "IT'S TIME TO DO IT!",
        "NEVER GIVE UP!",
        "KALK VE YAP! BAHANE YOK!",
        "ERTELEMEYİ BIRAK, HEMEN HAREKETE GEÇ!",
        "NO EXCUSES! KAMERAYI AÇ VE KANITLA!",
        "BUGÜN ERTELERSEN YARIN DA ERTELERSİN!",
        "KAÇIŞ YOK! 30 SANİYE HAREKET ET!"
    ]

    private init() {
        self.streakCount = UserDefaults.standard.integer(forKey: "nomindo_streak")
        loadAlarms()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    self.rescheduleAllNotifications()
                }
            }
        }
    }

    func addAlarm(hour: Int, minute: Int, label: String) {
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Günlük Antrenman" : label
        let newAlarm = WorkoutAlarm(hour: hour, minute: minute, label: cleanLabel, isEnabled: true)
        alarms.append(newAlarm)
        rescheduleAllNotifications()
    }

    func toggleAlarm(_ alarm: WorkoutAlarm) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx].isEnabled.toggle()
            rescheduleAllNotifications()
        }
    }

    func deleteAlarm(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        rescheduleAllNotifications()
    }

    func triggerAlarm(title: String) {
        activeAlarmLabel = title.isEmpty ? "SPOR VAKTİ!" : title
        dismissAttemptCount = 0
        currentPressureMessage = pressureMessages[0]
        isAlarmRinging = true
        AlarmSoundEngine.shared.startAlarm()
    }

    func registerDismissAttempt() {
        dismissAttemptCount += 1
        let index = dismissAttemptCount % pressureMessages.count
        currentPressureMessage = pressureMessages[index]
        AlarmSoundEngine.shared.startAlarm()
    }

    func completeVerification() {
        AlarmSoundEngine.shared.stopAlarm()
        isAlarmRinging = false
        dismissAttemptCount = 0
        streakCount += 1
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func rescheduleAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for alarm in alarms where alarm.isEnabled {
            // Schedule primary alarm + 4 relentless follow-up reminders every 1 minute
            for offset in 0..<5 {
                let content = UNMutableNotificationContent()
                content.title = "NOMINDO • HAREKETE GEÇ"
                if offset == 0 {
                    content.body = "\(alarm.label) — IT'S TIME TO DO IT!"
                } else {
                    content.body = "NEVER GIVE UP! (\(offset). Uyarı) Kalk ve kamerada kanıtla!"
                }
                content.sound = .default
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .timeSensitive
                }

                var totalMinutes = alarm.hour * 60 + alarm.minute + offset
                let targetHour = (totalMinutes / 60) % 24
                let targetMinute = totalMinutes % 60

                var dateComponents = DateComponents()
                dateComponents.hour = targetHour
                dateComponents.minute = targetMinute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)_\(offset)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "nomindo_alarms")
        }
    }

    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "nomindo_alarms"),
           let decoded = try? JSONDecoder().decode([WorkoutAlarm].self, from: data) {
            self.alarms = decoded
        } else {
            self.alarms = [
                WorkoutAlarm(hour: 8, minute: 0, label: "Sabah Kondisyon & Esneme", isEnabled: true)
            ]
        }
    }
}
