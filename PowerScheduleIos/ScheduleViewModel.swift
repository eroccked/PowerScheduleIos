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
    @Published var scheduleData: ScheduleData?
    @Published var isLoading = false
    @Published var errorMessage: String?
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
    
    init(queue: PowerQueue) {
        self.queue = queue
        self.notificationsEnabled = queue.isNotificationsEnabled
        self.autoUpdateEnabled = queue.isAutoUpdateEnabled
    }
    
    // MARK: - Fetch Schedule
    func fetchSchedule() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let data = try await apiService.fetchSchedule(for: queue.queueNumber)
                scheduleData = data
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
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
        guard let shutdowns = scheduleData?.shutdowns else { return }
        
        Task {
            await notificationService.scheduleShutdownNotifications(
                shutdowns: shutdowns,
                queueName: queue.name
            )
        }
    }
    
    private func cancelNotifications() {
        notificationService.cancelAllNotifications()
    }
}
