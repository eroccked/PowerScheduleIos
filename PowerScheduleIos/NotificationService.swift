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
        eventDate: String,
        showChangeNotification: Bool = false
    ) async {
        let hasChanges = await checkForScheduleChanges(for: queue)
        
        if hasChanges && showChangeNotification {
            await showScheduleUpdateNotification(queueName: queue.name)
        }
        
        await scheduleShutdownNotifications(
            shutdowns: shutdowns,
            queueName: queue.name,
            minutesBefore: minutesBefore,
            eventDate: eventDate
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
    /// Планує сповіщення для відключень
    /// - Parameters:
    ///   - shutdowns: масив відключень
    ///   - queueName: назва черги
    ///   - minutesBefore: за скільки хвилин попереджати
    ///   - eventDate: дата графіка (формат "dd.MM.yyyy") - ВАЖЛИВО для правильної дати сповіщення
    func scheduleShutdownNotifications(shutdowns: [Shutdown], queueName: String, minutesBefore: Int, eventDate: String) async {
        cancelNotifications(for: queueName)
        
        let authorized = await requestAuthorization()
        guard authorized else {
            print("Notification permission not granted")
            return
        }
        
        for shutdown in shutdowns {
            // Передаємо eventDate щоб сповіщення було на правильну дату
            guard let notificationDate = shutdown.notificationDate(minutesBefore: minutesBefore, eventDate: eventDate) else { continue }
            
            // Перевіряємо що дата в майбутньому
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "⚡ Скоро відключення!"
            
            let timeText = formatTimeText(minutes: minutesBefore)
            content.body = "\(queueName): відключення о \(shutdown.from) (\(timeText))"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Додаємо дату в ідентифікатор для унікальності
            let identifier = "shutdown_\(eventDate)_\(shutdown.from)_\(queueName)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Scheduled notification for \(eventDate) \(shutdown.from) (\(timeText) before)")
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
    
    // MARK: - Show New Tomorrow Schedule Notification
    /// Показує сповіщення коли з'явився новий графік на завтра
    func showNewTomorrowScheduleNotification(queueName: String, tomorrowDate: String, totalHours: Int, shutdownsCount: Int) async {
        // Перевіряємо чи увімкнено сповіщення про нові графіки
        guard StorageService.shared.loadNewScheduleNotificationEnabled() else { return }
        
        let authorized = await requestAuthorization()
        guard authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📅 Графік на завтра"
        content.body = "\(queueName): \(shutdownsCount) відключень, всього \(totalHours) год без світла"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "new_tomorrow_\(queueName)_\(tomorrowDate)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📅 Сповіщення про новий графік на завтра надіслано для \(queueName)")
        } catch {
            print("Error showing new tomorrow schedule notification: \(error)")
        }
    }
    
    // MARK: - Check and Notify New Tomorrow Schedule
    /// Перевіряє чи з'явився новий графік на завтра і сповіщає
    func checkAndNotifyNewTomorrowSchedule(for queue: PowerQueue, tomorrowSchedule: ScheduleData?) async {
        guard let tomorrow = tomorrowSchedule else { return }
        
        let lastDate = StorageService.shared.loadLastTomorrowScheduleDate(for: queue.id)
        
        // Якщо дата завтрашнього графіка нова — сповіщаємо
        if lastDate != tomorrow.eventDate {
            StorageService.shared.saveLastTomorrowScheduleDate(tomorrow.eventDate, for: queue.id)
            
            // Якщо це не перший запуск (lastDate != nil) — показуємо сповіщення
            if lastDate != nil {
                await showNewTomorrowScheduleNotification(
                    queueName: queue.name,
                    tomorrowDate: tomorrow.eventDate,
                    totalHours: tomorrow.totalHours,
                    shutdownsCount: tomorrow.shutdowns.count
                )
            }
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
