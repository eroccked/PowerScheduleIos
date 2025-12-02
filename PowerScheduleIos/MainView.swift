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
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "B8E0E8"),
                        Color(hex: "C0E5DB"),
                        Color(hex: "C8E6D5")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
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
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Графік світла")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Івано-Франківськ")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
    
    // MARK: - Section Title
    private var sectionTitle: some View {
        HStack {
            Text("Мої черги")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black.opacity(0.7))
            Spacer()
            
            Button(action: {
                viewModel.checkForUpdatesNow()
                refreshTrigger = UUID()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Оновити")
                        .font(.system(size: 11))
                }
                .foregroundColor(.black.opacity(0.6))
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 42))
                .foregroundColor(.black.opacity(0.3))
            
            Text("Немає збережених черг")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
            
            Text("Додайте першу чергу нижче")
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    // MARK: - Queues List
    private var queuesList: some View {
        ForEach(viewModel.queues) { queue in
            QueueCard(queue: queue, viewModel: viewModel, refreshTrigger: refreshTrigger)
        }
    }
    
    // MARK: - Add Queue Section
    private var addQueueSection: some View {
        Button(action: {
            showingAddQueue = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Додати чергу")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Queue Card (стиль Дія)
struct QueueCard: View {
    let queue: PowerQueue
    @ObservedObject var viewModel: MainViewModel
    let refreshTrigger: UUID
    
    @State private var showingSchedule = false
    @State private var schedulePreview: String = "Завантаження..."
    @State private var statusEmoji: String = "⏳"
    @State private var timer: Timer?
    @State private var currentQueue: PowerQueue
    @State private var isPowerOn: Bool = true
    @State private var showingMenu = false
    
    init(queue: PowerQueue, viewModel: MainViewModel, refreshTrigger: UUID) {
        self.queue = queue
        self.viewModel = viewModel
        self.refreshTrigger = refreshTrigger
        _currentQueue = State(initialValue: queue)
    }
    
    var body: some View {
        Button(action: {
            showingSchedule = true
        }) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(queue.name)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            showingMenu = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .rotationEffect(.degrees(90))
                                .padding(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Черга:")
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text(queue.queueNumber)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    HStack(spacing: 10) {
                        Circle()
                            .strokeBorder(isPowerOn ? Color(hex: "4CAF50") : Color(hex: "FF5252"), lineWidth: 3.5)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isPowerOn ? "Світло є" : "Відключення")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text(schedulePreview)
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                }
                .padding(18)
                
                HStack {
                    Text("Оновлено о \(getCurrentTime())")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color(hex: "A8E6CF").opacity(0.5))
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "E8F4F8"),
                                Color(hex: "E0F2F1")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("", isPresented: $showingMenu, titleVisibility: .hidden) {
            Button("Оновити графік") {
                Task {
                    await loadPreview()
                }
            }
            
            Button(currentQueue.isNotificationsEnabled ? "Вимкнути сповіщення" : "Увімкнути сповіщення") {
                toggleNotifications()
            }
            
            Button("Видалити", role: .destructive) {
                viewModel.deleteQueue(queue)
            }
            
            Button("Скасувати", role: .cancel) {}
        }
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
                    currentQueue.isNotificationsEnabled ? "Вимкнути сповіщення" : "Увімкнути сповіщення",
                    systemImage: currentQueue.isNotificationsEnabled ? "bell.slash.fill" : "bell.fill"
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
        .task(id: refreshTrigger) {
            await loadPreview()
            startAutoRefresh()
            syncQueueState()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .onChange(of: viewModel.queues) { _ in
            syncQueueState()
        }
    }
    
    // MARK: - Sync Queue State
    private func syncQueueState() {
        if let updatedQueue = viewModel.queues.first(where: { $0.id == queue.id }) {
            currentQueue = updatedQueue
        }
    }
    
    // MARK: - Auto Refresh
    private func startAutoRefresh() {
        stopAutoRefresh()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await loadPreview()
            }
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    private func loadPreview() async {
        do {
            let scheduleData = try await APIService.shared.fetchSchedule(for: queue.queueNumber)
            
            let currentHour = Calendar.current.component(.hour, from: Date())
            isPowerOn = scheduleData.hourlyTimeline[currentHour]
            
            if isPowerOn {
                if let nextShutdown = scheduleData.shutdowns.first(where: { shutdown in
                    let parts = shutdown.from.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2 else { return false }
                    return parts[0] > currentHour
                }) {
                    schedulePreview = "Відключення о \(nextShutdown.from)"
                } else {
                    if let firstShutdownTomorrow = scheduleData.shutdowns.first {
                        schedulePreview = "Відключення завтра о \(firstShutdownTomorrow.from)"
                    } else {
                        schedulePreview = "Відключень немає"
                    }
                }
            } else {
                if let nextPowerOn = findNextPowerOn(timeline: scheduleData.hourlyTimeline, currentHour: currentHour) {
                    schedulePreview = "Увімкнуть о ~\(nextPowerOn):00"
                } else {
                    if let firstPowerOnHour = scheduleData.hourlyTimeline.firstIndex(where: { $0 == true }) {
                        schedulePreview = "Увімкнуть завтра о ~\(firstPowerOnHour):00"
                    } else {
                        schedulePreview = "Поточний стан"
                    }
                }
            }
        } catch {
            isPowerOn = false
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
        currentQueue.isNotificationsEnabled.toggle()
        viewModel.updateQueue(currentQueue)
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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
