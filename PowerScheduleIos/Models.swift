//
//  Models.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import Foundation

// MARK: - PowerQueue Model
struct PowerQueue: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var queueNumber: String
    var isNotificationsEnabled: Bool
    var isAutoUpdateEnabled: Bool
    
    init(id: UUID = UUID(), name: String, queueNumber: String,
         isNotificationsEnabled: Bool = false, isAutoUpdateEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.queueNumber = queueNumber
        self.isNotificationsEnabled = isNotificationsEnabled
        self.isAutoUpdateEnabled = isAutoUpdateEnabled
    }
    
    static func == (lhs: PowerQueue, rhs: PowerQueue) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.queueNumber == rhs.queueNumber &&
               lhs.isNotificationsEnabled == rhs.isNotificationsEnabled &&
               lhs.isAutoUpdateEnabled == rhs.isAutoUpdateEnabled
    }
}

// MARK: - Schedule Response Model
struct ScheduleResponse: Codable {
    let eventDate: String
    let createdAt: String
    let scheduleApprovedSince: String
    let queues: [String: [Shutdown]]
}

// MARK: - Shutdown Model
struct Shutdown: Codable, Identifiable {
    var id: UUID { UUID() }
    let from: String
    let to: String
    let shutdownHours: String
    
    var durationMinutes: Int {
        let fromParts = from.split(separator: ":").compactMap { Int($0) }
        let toParts = to.split(separator: ":").compactMap { Int($0) }
        
        guard fromParts.count == 2, toParts.count == 2 else { return 0 }
        
        let fromMinutes = fromParts[0] * 60 + fromParts[1]
        let toMinutes = toParts[0] * 60 + toParts[1]
        
        return toMinutes - fromMinutes
    }
    
    func notificationDate(minutesBefore: Int) -> Date? {
        let parts = from.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts[0]
        components.minute = parts[1]
        
        guard let date = Calendar.current.date(from: components) else { return nil }
        // Віднімаємо потрібну кількість хвилин з налаштувань
        return Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: date)
    }
}

// MARK: - Schedule Data Model
struct ScheduleData: Codable {
    let eventDate: String
    let createdAt: String
    let scheduleApprovedSince: String
    let shutdowns: [Shutdown]
    
    var totalMinutesWithoutPower: Int {
        shutdowns.reduce(0) { $0 + $1.durationMinutes }
    }
    
    var totalHours: Int {
        totalMinutesWithoutPower / 60
    }
    
    var remainingMinutes: Int {
        totalMinutesWithoutPower % 60
    }

    var hourlyTimeline: [Bool] {
        var timeline = Array(repeating: true, count: 24)
        
        for shutdown in shutdowns {
            let fromParts = shutdown.from.split(separator: ":").compactMap { Int($0) }
            let toParts = shutdown.to.split(separator: ":").compactMap { Int($0) }
            
            guard fromParts.count == 2, toParts.count == 2 else { continue }
            
            let fromHour = fromParts[0]
            let toHour = toParts[0]
            
            for hour in fromHour..<min(toHour, 24) {
                timeline[hour] = false
            }
        }
        
        return timeline
    }
}
