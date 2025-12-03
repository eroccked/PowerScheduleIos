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
    @State private var contentHeight: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    private var shouldShowFooterButton: Bool {
        guard viewModel.queues.count > 2 else { return false }
        return contentHeight > screenHeight - 200
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
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
                                
                                if !shouldShowFooterButton {
                                    addQueueSection
                                }
                            }
                            .padding()
                            .padding(.bottom, shouldShowFooterButton ? 80 : 0)
                            .background(
                                GeometryReader { contentGeo in
                                    Color.clear.preference(
                                        key: ContentHeightPreferenceKey.self,
                                        value: contentGeo.size.height
                                    )
                                }
                            )
                        }
                        
                        if shouldShowFooterButton {
                            fixedAddButton
                        }
                    }
                    .onAppear {
                        screenHeight = geometry.size.height
                    }
                }
                .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                    contentHeight = height
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
            .onChange(of: viewModel.queues.count) { _ in
                contentHeight = 0
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
                    .font(.system(size: 18))
                Text("Додати чергу")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Fixed Add Button (Footer)
    private var fixedAddButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                showingAddQueue = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Додати чергу")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "C8E6D5").opacity(0.95),
                        Color(hex: "C8E6D5")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
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
                        
                        Spacer()
                        
                        Image(systemName: currentQueue.isNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.black.opacity(currentQueue.isNotificationsEnabled ? 0.7 : 0.3))
                            .padding(.trailing, 10)
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
            
            let _ = syncQueueStateAndReturn()
            
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
    
    private func syncQueueStateAndReturn() -> Bool {
        syncQueueState()
        return true
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
            
            let isToday = isDateToday(scheduleData.eventDate)
            
            // Визначаємо чи є світло ЗАРАЗ (з точністю до хвилини)
            let currentShutdown = findCurrentShutdown(shutdowns: scheduleData.shutdowns)
            isPowerOn = currentShutdown == nil
            
            if isPowerOn {
                // Світло є - шукаємо наступне відключення
                if let nextShutdown = findNextShutdown(shutdowns: scheduleData.shutdowns) {
                    schedulePreview = "Відключення о \(nextShutdown.from)"
                } else {
                    if let firstShutdown = scheduleData.shutdowns.first {
                        if isToday {
                            schedulePreview = "Сьогодні відключень більше немає"
                        } else {
                            schedulePreview = "Відключення завтра о \(firstShutdown.from)"
                        }
                    } else {
                        schedulePreview = "Відключень немає"
                    }
                }
            } else {
                // Світла немає - показуємо коли увімкнуть
                if let shutdown = currentShutdown {
                    schedulePreview = "Увімкнуть о \(shutdown.to)"
                } else {
                    schedulePreview = "Поточний стан"
                }
            }
        } catch {
            isPowerOn = false
            schedulePreview = "Помилка завантаження"
        }
    }
    
    // MARK: - Helper для перевірки дати
    private func isDateToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "uk_UA")
        
        guard let eventDate = formatter.date(from: dateString) else {
            return true
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(eventDate)
    }
    
    // Знаходить поточне відключення (в якому ми зараз знаходимось)
    private func findCurrentShutdown(shutdowns: [Shutdown]) -> Shutdown? {
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
    
    // Знаходить наступне відключення (яке ще не почалось)
    private func findNextShutdown(shutdowns: [Shutdown]) -> Shutdown? {
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
    
    // Знаходить час наступного увімкнення світла
    private func findNextPowerOnTime(shutdowns: [Shutdown], currentHour: Int) -> String? {
        let now = Date()
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Шукаємо найближче відключення яке закінчиться після поточного часу
        for shutdown in shutdowns {
            let toParts = shutdown.to.split(separator: ":").compactMap { Int($0) }
            guard toParts.count == 2 else { continue }
            
            let toMinutes = toParts[0] * 60 + toParts[1]
            
            if toMinutes > currentTotalMinutes {
                return shutdown.to
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

// MARK: - Preference Key для висоти контенту
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
