//
//  NotificationService.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import Foundation
import UserNotifications

// MARK: - Notification Service
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleShutdownNotifications(shutdowns: [Shutdown], queueName: String, minutesBefore: Int) async {
        cancelNotifications(for: queueName)
        
        let authorized = await requestAuthorization()
        guard authorized else {
            print("Notification permission not granted")
            return
        }
        
        for shutdown in shutdowns {
            guard let notificationDate = shutdown.notificationDate(minutesBefore: minutesBefore) else { continue }
            
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "⚡ Скоро відключення!"
            
            let timeText = formatTimeText(minutes: minutesBefore)
            content.body = "\(queueName): відключення о \(shutdown.from) (\(timeText))"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "shutdown_\(shutdown.from)_\(queueName)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Scheduled notification for \(shutdown.from) (\(timeText) before)")
            } catch {
                print("❌ Error scheduling notification: \(error)")
            }
        }
    }
    
    func showScheduleUpdateNotification(queueName: String) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Графік оновлено!"
        content.body = "Графік для \"\(queueName)\" змінився. Натисніть для перегляду."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "schedule_update_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error showing update notification: \(error)")
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for queueName: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(queueName) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    // MARK: - Helper
    private func formatTimeText(minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "через \(hours) год"
            } else {
                return "через \(hours) год \(mins) хв"
            }
        } else {
            return "через \(minutes) хв"
        }
    }
}
