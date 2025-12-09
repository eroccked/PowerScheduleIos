//
//  APIService.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import Foundation

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    private init() {}
    
    private let baseURL = "https://be-svitlo.oe.if.ua"
    
    // MARK: - Fetch Single Schedule (для карток на головному екрані)
    func fetchSchedule(for queueNumber: String) async throws -> ScheduleData {
        let allSchedules = try await fetchAllSchedules(for: queueNumber)
        
        
        if let today = allSchedules.today {
            let hasUpcoming = hasUpcomingShutdowns(shutdowns: today.shutdowns)
            
            if hasUpcoming {
                return today
            } else if let tomorrow = allSchedules.tomorrow {
                return tomorrow
            } else {
                return today
            }
        } else if let tomorrow = allSchedules.tomorrow {
            return tomorrow
        } else {
            throw APIError.noData
        }
    }
    
    // MARK: - Fetch All Schedules (для деталей черги - обидва дні)
    func fetchAllSchedules(for queueNumber: String) async throws -> AllSchedulesData {
        let urlString = "\(baseURL)/schedule-by-queue?queue=\(queueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let decoder = JSONDecoder()
        let scheduleArray = try decoder.decode([ScheduleResponse].self, from: data)
        
        guard !scheduleArray.isEmpty else {
            throw APIError.noData
        }
        
        let todaySchedule = findTodaySchedule(in: scheduleArray, queueNumber: queueNumber)
        let tomorrowSchedule = findTomorrowSchedule(in: scheduleArray, queueNumber: queueNumber)
        let yesterdaySchedule = findYesterdaySchedule(in: scheduleArray, queueNumber: queueNumber)
        
        return AllSchedulesData(
            yesterday: yesterdaySchedule,
            today: todaySchedule,
            tomorrow: tomorrowSchedule
        )
    }
    
    // MARK: - Helper: Знайти вчорашній графік
    private func findYesterdaySchedule(in schedules: [ScheduleResponse], queueNumber: String) -> ScheduleData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        let yesterdayString = formatter.string(from: yesterday)
        
        for schedule in schedules {
            if schedule.eventDate == yesterdayString,
               let shutdowns = schedule.queues[queueNumber] {
                return ScheduleData(
                    eventDate: schedule.eventDate,
                    createdAt: schedule.createdAt,
                    scheduleApprovedSince: schedule.scheduleApprovedSince,
                    shutdowns: shutdowns
                )
            }
        }
        return nil
    }
    
    // MARK: - Helper: Знайти сьогоднішній графік
    private func findTodaySchedule(in schedules: [ScheduleResponse], queueNumber: String) -> ScheduleData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        
        let todayString = formatter.string(from: Date())
        
        for schedule in schedules {
            if schedule.eventDate == todayString,
               let shutdowns = schedule.queues[queueNumber] {
                return ScheduleData(
                    eventDate: schedule.eventDate,
                    createdAt: schedule.createdAt,
                    scheduleApprovedSince: schedule.scheduleApprovedSince,
                    shutdowns: shutdowns
                )
            }
        }
        return nil
    }
    
    // MARK: - Helper: Знайти завтрашній графік
    private func findTomorrowSchedule(in schedules: [ScheduleResponse], queueNumber: String) -> ScheduleData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return nil
        }
        let tomorrowString = formatter.string(from: tomorrow)
        
        for schedule in schedules {
            if schedule.eventDate == tomorrowString,
               let shutdowns = schedule.queues[queueNumber] {
                return ScheduleData(
                    eventDate: schedule.eventDate,
                    createdAt: schedule.createdAt,
                    scheduleApprovedSince: schedule.scheduleApprovedSince,
                    shutdowns: shutdowns
                )
            }
        }
        return nil
    }
    
    // MARK: - Helper: Чи є майбутні або поточні відключення
    private func hasUpcomingShutdowns(shutdowns: [Shutdown]) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        for shutdown in shutdowns {
            let toParts = shutdown.to.split(separator: ":").compactMap { Int($0) }
            guard toParts.count == 2 else { continue }
            
            let toMinutes = toParts[0] * 60 + toParts[1]
            
            if toMinutes > currentTotalMinutes {
                return true
            }
        }
        return false
    }
}

// MARK: - All Schedules Data
struct AllSchedulesData {
    let yesterday: ScheduleData?
    let today: ScheduleData?
    let tomorrow: ScheduleData?
    
    var availableDays: [DayOption] {
        var days: [DayOption] = []
        
        if let y = yesterday, !y.shutdowns.isEmpty {
            days.append(.yesterday)
        }
        if today != nil {
            days.append(.today)
        }
        if tomorrow != nil {
            days.append(.tomorrow)
        }
        
        return days
    }
}

// MARK: - Day Option
enum DayOption: String, CaseIterable, Identifiable {
    case yesterday = "Вчора"
    case today = "Сьогодні"
    case tomorrow = "Завтра"
    
    var id: String { rawValue }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case serverError
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "❌ Невірне посилання"
        case .serverError:
            return "❌ Помилка сервера"
        case .noData:
            return "❌ Немає даних"
        case .decodingError:
            return "❌ Помилка обробки даних"
        }
    }
}
