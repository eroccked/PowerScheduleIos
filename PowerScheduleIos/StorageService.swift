//
//  StorageService.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//

import Foundation

// MARK: - Storage Service
class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    private let queuesKey = "saved_queues"
    private let updateIntervalKey = "update_interval"
    
    func saveQueues(_ queues: [PowerQueue]) {
        if let encoded = try? JSONEncoder().encode(queues) {
            UserDefaults.standard.set(encoded, forKey: queuesKey)
        }
    }
    
    func loadQueues() -> [PowerQueue] {
        guard let data = UserDefaults.standard.data(forKey: queuesKey),
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
        UserDefaults.standard.set(minutes, forKey: updateIntervalKey)
    }
    
    func loadUpdateInterval() -> Int {
        let interval = UserDefaults.standard.integer(forKey: updateIntervalKey)
        return interval > 0 ? interval : 15 // За замовчуванням 15 хвилин
    }
    
    func saveScheduleJSON(_ json: String, for queueId: UUID) {
        UserDefaults.standard.set(json, forKey: "schedule_\(queueId.uuidString)")
    }
    
    func loadScheduleJSON(for queueId: UUID) -> String? {
        return UserDefaults.standard.string(forKey: "schedule_\(queueId.uuidString)")
    }
}
