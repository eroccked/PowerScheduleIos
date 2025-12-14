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

// MARK: - Timeline Entry
struct PowerScheduleEntry: TimelineEntry {
    let date: Date
    let queueName: String
    let queueNumber: String
    let isPowerOn: Bool
    let statusText: String
    let updatedAt: String
    let isPlaceholder: Bool
    
    static var placeholder: PowerScheduleEntry {
        PowerScheduleEntry(
            date: Date(),
            queueName: "Дім",
            queueNumber: "5.2",
            isPowerOn: true,
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
            isPowerOn: true,
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
            let scheduleData = try await WidgetAPIService.fetchSchedule(for: queue.queueNumber)
            
            let isToday = isDateToday(scheduleData.eventDate)
            
            let statusText: String
            let isPowerOn: Bool
            
            if isToday {
                let currentShutdown = findCurrentShutdown(shutdowns: scheduleData.shutdowns)
                isPowerOn = currentShutdown == nil
                
                if isPowerOn {
                    if let nextShutdown = findNextShutdown(shutdowns: scheduleData.shutdowns) {
                        statusText = "Відключення о \(nextShutdown.from)"
                    } else {
                        statusText = "Сьогодні відключень більше немає"
                    }
                } else {
                    if let shutdown = currentShutdown {
                        statusText = "Увімкнуть о \(shutdown.to)"
                    } else {
                        statusText = "Світла немає"
                    }
                }
            } else {
                isPowerOn = true
                
                if let firstShutdown = scheduleData.shutdowns.first {
                    statusText = "Завтра відключення о \(firstShutdown.from)"
                } else {
                    statusText = "Завтра відключень немає"
                }
            }
            
            return Entry(
                date: Date(),
                queueName: queue.name,
                queueNumber: queue.queueNumber,
                isPowerOn: isPowerOn,
                statusText: statusText,
                updatedAt: updatedAt,
                isPlaceholder: false
            )
        } catch {
            // При помилці — "Даних немає" + світло є
            return Entry(
                date: Date(),
                queueName: queue.name,
                queueNumber: queue.queueNumber,
                isPowerOn: true,
                statusText: "Даних немає",
                updatedAt: updatedAt,
                isPlaceholder: false
            )
        }
    }
    
    private func isDateToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        
        guard let eventDate = formatter.date(from: dateString) else {
            return true
        }
        
        return Calendar.current.isDateInToday(eventDate)
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
            let toMinutes = toParts[0] * 60 + toParts[1]
            
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
                    .stroke(entry.isPowerOn ? Color.green : Color.red, lineWidth: 4)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.isPowerOn ? "Світло є" : "Світла немає")
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

//// MARK: - Preview
//#Preview(as: .systemMedium) {
//    PowerScheduleWidget()
//} timeline: {
//    PowerScheduleEntry.placeholder
//}
