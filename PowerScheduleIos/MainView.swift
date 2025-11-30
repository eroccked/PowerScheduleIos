//
//  MainView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import SwiftUI

// MARK: - Main View
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showingAddQueue = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "E3F2FD"), Color(hex: "BBDEFB")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    updateBanner
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            sectionTitle
                            
                            if viewModel.queues.isEmpty {
                                emptyStateView
                            } else {
                                queuesList
                            }
                            
                            addQueueSection
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showingAddQueue) {
                AddQueueView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .onDisappear {
                        viewModel.loadQueues()
                    }
            }
            .alert("Помилка", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.loadQueues()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            
            Text("💡")
                .font(.system(size: 40))
            
            Text("Графік Світла")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Івано-Франківськ")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "BBDEFB"))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(hex: "1976D2"))
    }
    
    // MARK: - Update Banner
    private var updateBanner: some View {
        HStack {
            Text("🔄 Автооновлення кожні \(viewModel.updateInterval) хв")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "1565C0"))
            
            Spacer()
            
            Button(action: {
                viewModel.checkForUpdatesNow()
            }) {
                Text("Оновити зараз")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "1976D2"))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(hex: "BBDEFB"))
    }
    
    // MARK: - Section Title
    private var sectionTitle: some View {
        HStack {
            Text("📋 Мої черги:")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "1976D2"))
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Text("Немає збережених черг")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "9E9E9E"))
            
            Text("Додайте першу чергу нижче ⬇️")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "9E9E9E"))
        }
        .frame(height: 150)
    }
    
    // MARK: - Queues List
    private var queuesList: some View {
        ForEach(viewModel.queues) { queue in
            QueueCard(queue: queue, viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Add Queue Section
    private var addQueueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                showingAddQueue = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("ДОДАТИ ЧЕРГУ")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "4CAF50"))
                .cornerRadius(12)
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - Queue Card
struct QueueCard: View {
    let queue: PowerQueue
    @ObservedObject var viewModel: MainViewModel
    @State private var showingSchedule = false
    @State private var schedulePreview: String = "Завантаження..."
    @State private var statusEmoji: String = "⏳"
    
    var body: some View {
        Button(action: {
            showingSchedule = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("📍 \(queue.name)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "1976D2"))
                    Spacer()
                }
                
                HStack {
                    Text("Черга: \(queue.queueNumber)")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "424242"))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusEmoji)
                            .font(.system(size: 24))
                        
                        Text(schedulePreview)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "757575"))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                Task {
                    await loadPreview()
                }
            }) {
                Label("Оновити графік", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                toggleNotifications()
            }) {
                Label(
                    queue.isNotificationsEnabled ? "Вимкнути сповіщення" : "Увімкнути сповіщення",
                    systemImage: queue.isNotificationsEnabled ? "bell.slash.fill" : "bell.fill"
                )
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                viewModel.deleteQueue(queue)
            }) {
                Label("Видалити", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingSchedule) {
            ScheduleView(queue: queue)
        }
        .task {
            await loadPreview()
        }
    }
    
    private func loadPreview() async {
        do {
            let scheduleData = try await APIService.shared.fetchSchedule(for: queue.queueNumber)
            
            let currentHour = Calendar.current.component(.hour, from: Date())
            let isPowerOn = scheduleData.hourlyTimeline[currentHour]
            
            if isPowerOn {
                statusEmoji = "🟢"
                
                if let nextShutdown = scheduleData.shutdowns.first(where: { shutdown in
                    let parts = shutdown.from.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2 else { return false }
                    return parts[0] > currentHour
                }) {
                    schedulePreview = "Відключення: \(nextShutdown.from)"
                } else {
                    schedulePreview = "Світло є"
                }
            } else {
                statusEmoji = "🔴"
                
                if let nextPowerOn = findNextPowerOn(timeline: scheduleData.hourlyTimeline, currentHour: currentHour) {
                    schedulePreview = "Увімкнуть: ~\(nextPowerOn):00"
                } else {
                    schedulePreview = "Зараз відключення"
                }
            }
        } catch {
            statusEmoji = "⚠️"
            schedulePreview = "Помилка завантаження"
        }
    }
    
    private func findNextPowerOn(timeline: [Bool], currentHour: Int) -> Int? {
        for hour in (currentHour + 1)..<24 {
            if timeline[hour] {
                return hour
            }
        }
        for hour in 0..<currentHour {
            if timeline[hour] {
                return hour
            }
        }
        return nil
    }
    
    private func toggleNotifications() {
        var updatedQueue = queue
        updatedQueue.isNotificationsEnabled.toggle()
        viewModel.updateQueue(updatedQueue)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
//#Preview {
//    MainView()
//}
