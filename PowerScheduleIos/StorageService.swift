//
//  StorageService.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import Foundation
import WidgetKit

// MARK: - Storage Service
class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    private let appGroupID = "group.com.tarasburha.powerschedule"
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
    
    private let queuesKey = "saved_queues"
    private let updateIntervalKey = "update_interval"
    private let notificationMinutesKey = "notification_minutes_before"
    
    func saveQueues(_ queues: [PowerQueue]) {
        if let encoded = try? JSONEncoder().encode(queues) {
            sharedDefaults.set(encoded, forKey: queuesKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
   
    func loadQueues() -> [PowerQueue] {
        guard let data = sharedDefaults.data(forKey: queuesKey),
              let queues = try? JSONDecoder().decode([PowerQueue].self, from: data) else {
            return []
        }
        return queues
    }
    
    func addQueue(_ queue: PowerQueue) {
        var queues = loadQueues()
        queues.append(queue)
        saveQueues(queues)
    }

    func deleteQueue(_ queue: PowerQueue) {
        var queues = loadQueues()
        queues.removeAll { $0.id == queue.id }
        saveQueues(queues)
    }
    
    func updateQueue(_ queue: PowerQueue) {
        var queues = loadQueues()
        if let index = queues.firstIndex(where: { $0.id == queue.id }) {
            queues[index] = queue
            saveQueues(queues)
        }
    }
    
    func saveUpdateInterval(_ minutes: Int) {
        sharedDefaults.set(minutes, forKey: updateIntervalKey)
    }
    
    func loadUpdateInterval() -> Int {
        let interval = sharedDefaults.integer(forKey: updateIntervalKey)
        return interval > 0 ? interval : 15
    }
    
    func saveScheduleJSON(_ json: String, for queueId: UUID) {
        sharedDefaults.set(json, forKey: "schedule_\(queueId.uuidString)")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func loadScheduleJSON(for queueId: UUID) -> String? {
        return sharedDefaults.string(forKey: "schedule_\(queueId.uuidString)")
    }
    
    func saveNotificationMinutes(_ minutes: Int) {
        sharedDefaults.set(minutes, forKey: notificationMinutesKey)
    }
    
    func loadNotificationMinutes() -> Int {
        let minutes = sharedDefaults.integer(forKey: notificationMinutesKey)
        return minutes > 0 ? minutes : 30
    }
}
