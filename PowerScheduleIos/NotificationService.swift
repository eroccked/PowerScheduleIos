//
//  NotificationService.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
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
    
    // MARK: - Schedule Notifications with Change Detection (for Background)
    func scheduleShutdownNotificationsWithChangeDetection(
        for queue: PowerQueue,
        shutdowns: [Shutdown],
        minutesBefore: Int,
        showChangeNotification: Bool = false
    ) async {
        let hasChanges = await checkForScheduleChanges(for: queue)
        
        if hasChanges && showChangeNotification {
            await showScheduleUpdateNotification(queueName: queue.name)
        }
        
        await scheduleShutdownNotifications(
            shutdowns: shutdowns,
            queueName: queue.name,
            minutesBefore: minutesBefore
        )
    }
    
    // MARK: - Check for Schedule Changes
    func checkForScheduleChanges(for queue: PowerQueue) async -> Bool {
        do {
            let scheduleData = try await APIService.shared.fetchSchedule(for: queue.queueNumber)
            
            guard let jsonData = try? JSONEncoder().encode(scheduleData),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return false
            }
            
            let savedJSON = StorageService.shared.loadScheduleJSON(for: queue.id)
            
            if let saved = savedJSON, saved != jsonString {
                StorageService.shared.saveScheduleJSON(jsonString, for: queue.id)
                print("📊 Виявлено зміни в графіку для \(queue.name)")
                return true
            } else if savedJSON == nil {
                StorageService.shared.saveScheduleJSON(jsonString, for: queue.id)
            }
            
            return false
        } catch {
            print("❌ Помилка перевірки змін: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Shutdown Notifications
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
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
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
    
    // MARK: - Show Schedule Update Notification
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
            print("📊 Сповіщення про зміну графіка надіслано для \(queueName)")
        } catch {
            print("Error showing update notification: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
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
