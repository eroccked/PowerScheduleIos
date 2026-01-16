//
//  PowerScheduleWidget.swift
//  PowerScheduleWidgetExtension
//
//  Created by Taras Buhra on 03.12.2025.
//
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Group ID
let appGroupID = "group.com.tarasburha.powerschedule"

// MARK: - Shared UserDefaults
extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

// MARK: - Queue Entity для вибору в налаштуваннях віджета
struct QueueEntity: AppEntity {
    let id: String
    let name: String
    let queueNumber: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Черга"
    static var defaultQuery = QueueEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) (\(queueNumber))")
    }
}

// MARK: - Query для отримання списку черг
struct QueueEntityQuery: EntityQuery {
    func entities(for identifiers: [QueueEntity.ID]) async throws -> [QueueEntity] {
        let allQueues = loadQueuesFromStorage()
        return allQueues.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [QueueEntity] {
        return loadQueuesFromStorage()
    }
    
    func defaultResult() async -> QueueEntity? {
        return loadQueuesFromStorage().first
    }
    
    private func loadQueuesFromStorage() -> [QueueEntity] {
        guard let data = UserDefaults.shared.data(forKey: "saved_queues"),
              let queues = try? JSONDecoder().decode([WidgetPowerQueue].self, from: data) else {
            return []
        }
        return queues.map { QueueEntity(id: $0.id.uuidString, name: $0.name, queueNumber: $0.queueNumber) }
    }
}

// MARK: - Widget Configuration Intent
struct SelectQueueIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Вибрати чергу"
    static var description = IntentDescription("Виберіть чергу для відображення")
    
    @Parameter(title: "Черга")
    var queue: QueueEntity?
}

// MARK: - Widget Power Status
enum WidgetPowerStatus: String {
    case on      // зелений
    case off     // червоний
    case unknown // жовтий
}

// MARK: - Timeline Entry
struct PowerScheduleEntry: TimelineEntry {
    let date: Date
    let queueName: String
    let queueNumber: String
    let powerStatus: WidgetPowerStatus
    let statusText: String
    let updatedAt: String
    let isPlaceholder: Bool
    
    static var placeholder: PowerScheduleEntry {
        PowerScheduleEntry(
            date: Date(),
            queueName: "Дім",
            queueNumber: "5.2",
            powerStatus: .on,
            statusText: "Сьогодні відключень більше немає",
            updatedAt: "16:35",
            isPlaceholder: true
        )
    }
    
    static var noQueue: PowerScheduleEntry {
        PowerScheduleEntry(
            date: Date(),
            queueName: "Немає черг",
            queueNumber: "-",
            powerStatus: .unknown,
            statusText: "Додайте чергу в додатку",
            updatedAt: "--:--",
            isPlaceholder: false
        )
    }
}

// MARK: - Timeline Provider
struct PowerScheduleProvider: AppIntentTimelineProvider {
    typealias Entry = PowerScheduleEntry
    typealias Intent = SelectQueueIntent
    
    func placeholder(in context: Context) -> Entry {
        .placeholder
    }
    
    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        await getEntry(for: configuration)
    }
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = await getEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func getEntry(for configuration: Intent) async -> Entry {
        guard let selectedQueue = configuration.queue else {
            let queues = loadQueues()
            guard let firstQueue = queues.first else {
                return .noQueue
            }
            return await fetchScheduleEntry(for: firstQueue)
        }
        
        let queue = WidgetPowerQueue(
            id: UUID(uuidString: selectedQueue.id) ?? UUID(),
            name: selectedQueue.name,
            queueNumber: selectedQueue.queueNumber
        )
        
        return await fetchScheduleEntry(for: queue)
    }
    
    private func loadQueues() -> [WidgetPowerQueue] {
        guard let data = UserDefaults.shared.data(forKey: "saved_queues"),
              let queues = try? JSONDecoder().decode([WidgetPowerQueue].self, from: data) else {
            return []
        }
        return queues
    }
    
    private func fetchScheduleEntry(for queue: WidgetPowerQueue) async -> Entry {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let updatedAt = timeFormatter.string(from: Date())
        
        do {
            // Завантажуємо всі графіки (сьогодні і завтра)
            let allSchedules = try await WidgetAPIService.fetchAllSchedules(for: queue.queueNumber)
            
            // Кешуємо успішно завантажені дані
            WidgetCacheService.saveCachedSchedule(allSchedules, for: queue.id)
            
            return processSchedulesForWidget(allSchedules, queue: queue, updatedAt: updatedAt, isFromCache: false)
            
        } catch {
            // При помилці — пробуємо показати кешовані дані
            if let cached = WidgetCacheService.loadCachedSchedule(for: queue.id),
               WidgetCacheService.isCacheValidForToday(for: queue.id) {
                return processSchedulesForWidget(cached.asAllSchedules, queue: queue, updatedAt: updatedAt, isFromCache: true)
            } else {
                // Немає кешу або він застарів
                return Entry(
                    date: Date(),
                    queueName: queue.name,
                    queueNumber: queue.queueNumber,
                    powerStatus: .unknown,
                    statusText: "Не вдалося оновити",
                    updatedAt: updatedAt,
                    isPlaceholder: false
                )
            }
        }
    }
    
    private func processSchedulesForWidget(_ allSchedules: WidgetAPIService.AllWidgetSchedules, queue: WidgetPowerQueue, updatedAt: String, isFromCache: Bool) -> Entry {
        let cachePrefix = isFromCache ? "⚠️ " : ""
        
        var statusText: String
        var powerStatus: WidgetPowerStatus
        
        // Спочатку перевіряємо сьогоднішній графік
        if let todaySchedule = allSchedules.today {
            let currentShutdown = findCurrentShutdown(shutdowns: todaySchedule.shutdowns)
            
            if let shutdown = currentShutdown {
                powerStatus = .off
                statusText = "\(cachePrefix)Увімкнуть о \(shutdown.to)"
                
                return Entry(
                    date: Date(),
                    queueName: queue.name,
                    queueNumber: queue.queueNumber,
                    powerStatus: powerStatus,
                    statusText: statusText,
                    updatedAt: updatedAt,
                    isPlaceholder: false
                )
            }
            
            if let nextShutdown = findNextShutdown(shutdowns: todaySchedule.shutdowns) {
                powerStatus = .on
                statusText = "\(cachePrefix)Відключення о \(nextShutdown.from)"
                
                return Entry(
                    date: Date(),
                    queueName: queue.name,
                    queueNumber: queue.queueNumber,
                    powerStatus: powerStatus,
                    statusText: statusText,
                    updatedAt: updatedAt,
                    isPlaceholder: false
                )
            }
        }
        
        // Дивимось на завтра
        if let tomorrowSchedule = allSchedules.tomorrow {
            powerStatus = .on
            if let firstShutdown = tomorrowSchedule.shutdowns.first {
                statusText = "\(cachePrefix)Завтра о \(firstShutdown.from)"
            } else {
                statusText = "\(cachePrefix)Завтра відключень немає"
            }
        } else if allSchedules.today != nil {
            powerStatus = .on
            statusText = "\(cachePrefix)Відключень більше немає"
        } else {
            powerStatus = .unknown
            statusText = "Дані недоступні"
        }
        
        return Entry(
            date: Date(),
            queueName: queue.name,
            queueNumber: queue.queueNumber,
            powerStatus: powerStatus,
            statusText: statusText,
            updatedAt: updatedAt,
            isPlaceholder: false
        )
    }
    
    private func findCurrentShutdown(shutdowns: [WidgetShutdown]) -> WidgetShutdown? {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        for shutdown in shutdowns {
            let fromParts = shutdown.from.split(separator: ":").compactMap { Int($0) }
            let toParts = shutdown.to.split(separator: ":").compactMap { Int($0) }
            
            guard fromParts.count == 2, toParts.count == 2 else { continue }
            
            let fromMinutes = fromParts[0] * 60 + fromParts[1]
            var toMinutes = toParts[0] * 60 + toParts[1]
            
            // Обробка переходу через північ (наприклад 20:30 - 00:00)
            if toMinutes <= fromMinutes {
                toMinutes += 24 * 60 // Додаємо 24 години
            }
            
            if currentTotalMinutes >= fromMinutes && currentTotalMinutes < toMinutes {
                return shutdown
            }
        }
        return nil
    }
    
    private func findNextShutdown(shutdowns: [WidgetShutdown]) -> WidgetShutdown? {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        for shutdown in shutdowns {
            let fromParts = shutdown.from.split(separator: ":").compactMap { Int($0) }
            guard fromParts.count == 2 else { continue }
            
            let fromMinutes = fromParts[0] * 60 + fromParts[1]
            
            if fromMinutes > currentTotalMinutes {
                return shutdown
            }
        }
        return nil
    }
}

// MARK: - Widget View
struct PowerScheduleWidgetView: View {
    var entry: PowerScheduleEntry
    
    // Колір кружка залежно від статусу
    private var statusColor: Color {
        switch entry.powerStatus {
        case .on:
            return Color.green
        case .off:
            return Color.red
        case .unknown:
            return Color.yellow
        }
    }
    
    // Текст статусу
    private var statusTitle: String {
        switch entry.powerStatus {
        case .on:
            return "Світло є"
        case .off:
            return "Світла немає"
        case .unknown:
            return "Інформація відсутня"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.queueName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 8)
            
            Text("Черга:")
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.6))
            
            Text(entry.queueNumber)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 10)
            
            HStack(spacing: 10) {
                Circle()
                    .stroke(statusColor, lineWidth: 4)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(entry.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Spacer()
            
            Text("Оновлено о \(entry.updatedAt)")
                .font(.system(size: 11))
                .foregroundColor(.black.opacity(0.5))
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.96, blue: 0.97),
                    Color(red: 0.88, green: 0.95, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Widget Definition
struct PowerScheduleWidget: Widget {
    let kind: String = "PowerScheduleWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectQueueIntent.self,
            provider: PowerScheduleProvider()
        ) { entry in
            PowerScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Графік світла")
        .description("Показує статус електропостачання для вибраної черги")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Models for Widget
struct WidgetPowerQueue: Codable {
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
}

struct WidgetShutdown: Codable {
    let from: String
    let to: String
    let shutdownHours: String
}

struct WidgetScheduleResponse: Codable {
    let eventDate: String
    let createdAt: String
    let scheduleApprovedSince: String
    let queues: [String: [WidgetShutdown]]
}

struct WidgetScheduleData: Codable {
    let eventDate: String
    let shutdowns: [WidgetShutdown]
}

// MARK: - API Service for Widget
struct WidgetAPIService {
    private static let baseURL = "https://be-svitlo.oe.if.ua"
    
    // Структура для всіх графіків
    struct AllWidgetSchedules {
        let today: WidgetScheduleData?
        let tomorrow: WidgetScheduleData?
    }
    
    // Завантажує всі доступні графіки (сьогодні і завтра)
    static func fetchAllSchedules(for queueNumber: String) async throws -> AllWidgetSchedules {
        let urlString = "\(baseURL)/schedule-by-queue?queue=\(queueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let scheduleArray = try JSONDecoder().decode([WidgetScheduleResponse].self, from: data)
        
        guard !scheduleArray.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        
        let todaySchedule = findTodaySchedule(in: scheduleArray, queueNumber: queueNumber)
        let tomorrowSchedule = findTomorrowSchedule(in: scheduleArray, queueNumber: queueNumber)
        
        return AllWidgetSchedules(today: todaySchedule, tomorrow: tomorrowSchedule)
    }
    
    static func fetchSchedule(for queueNumber: String) async throws -> WidgetScheduleData {
        let urlString = "\(baseURL)/schedule-by-queue?queue=\(queueNumber)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let scheduleArray = try JSONDecoder().decode([WidgetScheduleResponse].self, from: data)
        
        guard !scheduleArray.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        
        // Знаходимо сьогоднішній і завтрашній графіки
        let todaySchedule = findTodaySchedule(in: scheduleArray, queueNumber: queueNumber)
        let tomorrowSchedule = findTomorrowSchedule(in: scheduleArray, queueNumber: queueNumber)
        
        // Логіка вибору
        if let today = todaySchedule {
            let hasUpcoming = hasUpcomingShutdowns(shutdowns: today.shutdowns)
            
            if hasUpcoming {
                return today
            } else if let tomorrow = tomorrowSchedule {
                return tomorrow
            } else {
                return today
            }
        } else if let tomorrow = tomorrowSchedule {
            return tomorrow
        } else if let first = scheduleArray.first,
                  let shutdowns = first.queues[queueNumber] {
            return WidgetScheduleData(eventDate: first.eventDate, shutdowns: shutdowns)
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
    
    private static func findTodaySchedule(in schedules: [WidgetScheduleResponse], queueNumber: String) -> WidgetScheduleData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        let todayString = formatter.string(from: Date())
        
        for schedule in schedules {
            if schedule.eventDate == todayString,
               let shutdowns = schedule.queues[queueNumber] {
                return WidgetScheduleData(eventDate: schedule.eventDate, shutdowns: shutdowns)
            }
        }
        return nil
    }
    
    private static func findTomorrowSchedule(in schedules: [WidgetScheduleResponse], queueNumber: String) -> WidgetScheduleData? {
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
                return WidgetScheduleData(eventDate: schedule.eventDate, shutdowns: shutdowns)
            }
        }
        return nil
    }
    
    private static func hasUpcomingShutdowns(shutdowns: [WidgetShutdown]) -> Bool {
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

// MARK: - Widget Cache Service
struct WidgetCacheService {
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
    
    static func saveCachedSchedule(_ allSchedules: WidgetAPIService.AllWidgetSchedules, for queueId: UUID) {
        let cache = WidgetCachedSchedule(
            today: allSchedules.today,
            tomorrow: allSchedules.tomorrow,
            cachedAt: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(cache) {
            sharedDefaults.set(encoded, forKey: "widget_cache_\(queueId.uuidString)")
        }
    }
    
    static func loadCachedSchedule(for queueId: UUID) -> WidgetCachedSchedule? {
        guard let data = sharedDefaults.data(forKey: "widget_cache_\(queueId.uuidString)"),
              let cache = try? JSONDecoder().decode(WidgetCachedSchedule.self, from: data) else {
            return nil
        }
        return cache
    }
    
    static func isCacheValidForToday(for queueId: UUID) -> Bool {
        guard let cache = loadCachedSchedule(for: queueId) else { return false }
        return Calendar.current.isDateInToday(cache.cachedAt)
    }
}

// MARK: - Widget Cached Schedule
struct WidgetCachedSchedule: Codable {
    let today: WidgetScheduleData?
    let tomorrow: WidgetScheduleData?
    let cachedAt: Date
    
    var asAllSchedules: WidgetAPIService.AllWidgetSchedules {
        WidgetAPIService.AllWidgetSchedules(today: today, tomorrow: tomorrow)
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    PowerScheduleWidget()
} timeline: {
    PowerScheduleEntry.placeholder
}
