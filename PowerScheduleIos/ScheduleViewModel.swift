//
//  ScheduleViewModel.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//

import Foundation
import SwiftUI

// MARK: - Schedule View Model
@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var allSchedules: AllSchedulesData?
    @Published var selectedDay: DayOption = .today
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFromCache = false  // Чи дані з кешу
    @Published var notificationsEnabled: Bool {
        didSet {
            updateQueueSettings()
            if notificationsEnabled {
                scheduleNotifications()
            } else {
                cancelNotifications()
            }
        }
    }
    @Published var autoUpdateEnabled: Bool {
        didSet {
            updateQueueSettings()
        }
    }
    
    private let queue: PowerQueue
    private let apiService = APIService.shared
    private let storageService = StorageService.shared
    private let notificationService = NotificationService.shared
    
    // Поточний графік на основі вибраного дня
    var currentSchedule: ScheduleData? {
        guard let all = allSchedules else { return nil }
        
        switch selectedDay {
        case .yesterday:
            return all.yesterday
        case .today:
            return all.today
        case .tomorrow:
            return all.tomorrow
        }
    }
    
    // Доступні дні для перемикача
    var availableDays: [DayOption] {
        allSchedules?.availableDays ?? []
    }
    
    // Чи показувати перемикач днів
    var showDayPicker: Bool {
        availableDays.count > 1
    }
    
    init(queue: PowerQueue) {
        self.queue = queue
        self.notificationsEnabled = queue.isNotificationsEnabled
        self.autoUpdateEnabled = queue.isAutoUpdateEnabled
    }
    
    // MARK: - Fetch Schedule
    func fetchSchedule() {
        isLoading = true
        errorMessage = nil
        isFromCache = false
        
        Task {
            do {
                let data = try await apiService.fetchAllSchedules(for: queue.queueNumber)
                
                // Кешуємо успішно завантажені дані
                storageService.saveCachedSchedule(data, for: queue.id)
                
                allSchedules = data
                isFromCache = false
                
                selectInitialDay()
                
                isLoading = false
                
                if notificationsEnabled, let schedule = currentSchedule {
                    scheduleNotificationsFor(schedule)
                }
            } catch {
                // При помилці — пробуємо показати кешовані дані
                if let cached = storageService.loadCachedSchedule(for: queue.id),
                   storageService.isCacheValidForToday(for: queue.id) {
                    // Показуємо кешовані дані
                    allSchedules = cached.asAllSchedulesData
                    isFromCache = true
                    selectInitialDay()
                    isLoading = false
                    // Не показуємо errorMessage, бо є кеш
                } else {
                    // Немає кешу або він застарів
                    errorMessage = "Не вдалося завантажити дані. Перевірте підключення до інтернету."
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Select Initial Day
    private func selectInitialDay() {
        guard let all = allSchedules else { return }
        
        if let today = all.today, hasUpcomingShutdowns(shutdowns: today.shutdowns) {
            selectedDay = .today
        }
        else if all.tomorrow != nil {
            selectedDay = .tomorrow
        }
        else if all.today != nil {
            selectedDay = .today
        }
        else if all.yesterday != nil {
            selectedDay = .yesterday
        }
    }
    
    // MARK: - Check Upcoming Shutdowns
    private func hasUpcomingShutdowns(shutdowns: [Shutdown]) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        for shutdown in shutdowns {
            let toParts = shutdown.to.split(separator: ":").compactMap { Int($0) }
            guard toParts.count == 2 else { continue }
            
            var toMinutes = toParts[0] * 60 + toParts[1]
            
            // Обробка переходу через північ
            let fromParts = shutdown.from.split(separator: ":").compactMap { Int($0) }
            if fromParts.count == 2 {
                let fromMinutes = fromParts[0] * 60 + fromParts[1]
                if toMinutes <= fromMinutes {
                    toMinutes += 24 * 60
                }
            }
            
            if toMinutes > currentTotalMinutes {
                return true
            }
        }
        return false
    }
    
    // MARK: - Update Settings
    private func updateQueueSettings() {
        var updatedQueue = queue
        updatedQueue.isNotificationsEnabled = notificationsEnabled
        updatedQueue.isAutoUpdateEnabled = autoUpdateEnabled
        storageService.updateQueue(updatedQueue)
    }
    
    // MARK: - Notifications
    private func scheduleNotifications() {
        guard let schedule = currentSchedule else { return }
        scheduleNotificationsFor(schedule)
    }
    
    private func scheduleNotificationsFor(_ schedule: ScheduleData) {
        Task {
            let minutesBefore = storageService.loadNotificationMinutes()
            
            await notificationService.scheduleShutdownNotificationsWithChangeDetection(
                for: queue,
                shutdowns: schedule.shutdowns,
                minutesBefore: minutesBefore,
                eventDate: schedule.eventDate,
                showChangeNotification: false
            )
        }
    }
    
    private func cancelNotifications() {
        notificationService.cancelNotifications(for: queue.name)
    }
}
