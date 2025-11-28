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
    
    func fetchSchedule(for queueNumber: String) async throws -> ScheduleData {
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
        
        guard let scheduleResponse = scheduleArray.first,
              let shutdowns = scheduleResponse.queues[queueNumber] else {
            throw APIError.noData
        }
        
        return ScheduleData(
            eventDate: scheduleResponse.eventDate,
            createdAt: scheduleResponse.createdAt,
            scheduleApprovedSince: scheduleResponse.scheduleApprovedSince,
            shutdowns: shutdowns
        )
    }
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
