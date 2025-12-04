//
//  SettingsView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Налаштування")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        
                        VStack(spacing: 12) {
                            SettingsCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "bolt.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.black)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Графік Світла")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                        Text("Версія 1.0.0")
                                            .font(.system(size: 13))
                                            .foregroundColor(.black.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(18)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Автооновлення")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 22)
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "arrow.clockwise",
                                        title: "Інтервал оновлення",
                                        subtitle: "Кожні \(viewModel.updateInterval) хв"
                                    ) {
                                        Picker("", selection: $viewModel.updateInterval) {
                                            Text("5 хв").tag(5)
                                            Text("10 хв").tag(10)
                                            Text("15 хв").tag(15)
                                            Text("30 хв").tag(30)
                                            Text("60 хв").tag(60)
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.black)
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 54)
                                    
                                    Button(action: {
                                        viewModel.checkForUpdatesNow()
                                    }) {
                                        SettingsRow(
                                            icon: "arrow.triangle.2.circlepath",
                                            title: "Оновити зараз",
                                            subtitle: nil
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сповіщення")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 22)
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "bell.fill",
                                        title: "Дозволити сповіщення",
                                        subtitle: viewModel.notificationsEnabled ? "Увімкнено" : "Вимкнено"
                                    ) {
                                        Toggle("", isOn: $viewModel.notificationsEnabled)
                                            .labelsHidden()
                                            .tint(Color(hex: "4CAF50"))
                                    }
                                    
                                    if viewModel.notificationsEnabled {
                                        Divider()
                                            .padding(.leading, 60)
                                        
                                        NavigationLink(destination: NotificationTimePickerView(viewModel: viewModel)) {
                                            SettingsRow(
                                                icon: "clock.fill",
                                                title: "Попереджати за",
                                                subtitle: viewModel.notificationTimeText
                                            ) {
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.black.opacity(0.3))
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    Button(action: {
                                        viewModel.openNotificationSettings()
                                    }) {
                                        SettingsRow(
                                            icon: "gearshape.fill",
                                            title: "Налаштування iOS",
                                            subtitle: nil
                                        ) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black.opacity(0.3))
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Статистика")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 22)
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "list.bullet",
                                        title: "Всього черг",
                                        subtitle: nil
                                    ) {
                                        Text("\(viewModel.totalQueues)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.5))
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    SettingsRow(
                                        icon: "checkmark.circle.fill",
                                        title: "Активних оновлень",
                                        subtitle: nil
                                    ) {
                                        Text("\(viewModel.activeQueues)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.5))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Небезпечна зона")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 22)
                            
                            SettingsCard {
                                Button(action: {
                                    viewModel.showDeleteAllAlert = true
                                }) {
                                    SettingsRow(
                                        icon: "trash.fill",
                                        title: "Видалити всі черги",
                                        subtitle: nil,
                                        isDestructive: true
                                    )
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Інформація")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 22)
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    Link(destination: URL(string: "https://be-svitlo.oe.if.ua")!) {
                                        SettingsRow(
                                            icon: "link",
                                            title: "Джерело даних",
                                            subtitle: nil
                                        ) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black.opacity(0.3))
                                        }
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 54)
                                    
                                    Link(destination: URL(string: "https://t.me/buhra_t")!) {
                                        SettingsRow(
                                            icon: "paperplane.fill",
                                            title: "Розробник у Telegram",
                                            subtitle: nil
                                        ) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black.opacity(0.3))
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                }
            }
            .alert("Видалити всі черги?", isPresented: $viewModel.showDeleteAllAlert) {
                Button("Скасувати", role: .cancel) {}
                Button("Видалити", role: .destructive) {
                    viewModel.deleteAllQueues()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            } message: {
                Text("Це видалить всі збережені черги. Цю дію не можна скасувати.")
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
            )
            .padding(.horizontal, 18)
    }
}

// MARK: - Settings Row
struct SettingsRow<Accessory: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    let accessory: Accessory
    
    init(
        icon: String,
        title: String,
        subtitle: String?,
        isDestructive: Bool = false,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.accessory = accessory()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDestructive ? .red : .black)
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(isDestructive ? .red : .black)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            Spacer()
            
            accessory
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }
}

// MARK: - Settings View Model
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var updateInterval: Int = 15 {
        didSet {
            StorageService.shared.saveUpdateInterval(updateInterval)
        }
    }
    @Published var notificationMinutes: Int = 30 {
        didSet {
            StorageService.shared.saveNotificationMinutes(notificationMinutes)
        }
    }
    @Published var notificationsEnabled = false
    @Published var totalQueues = 0
    @Published var activeQueues = 0
    @Published var showDeleteAllAlert = false
    
    private let storageService = StorageService.shared
    
    var notificationTimeText: String {
        let hours = notificationMinutes / 60
        let mins = notificationMinutes % 60
        
        if notificationMinutes < 60 {
            return "\(notificationMinutes) хв"
        } else if mins == 0 {
            return "\(hours) год"
        } else {
            return "\(hours) год \(mins) хв"
        }
    }
    
    func loadData() {
        updateInterval = storageService.loadUpdateInterval()
        notificationMinutes = storageService.loadNotificationMinutes()
        checkNotificationPermission()
        updateStats()
    }
    
    func updateStats() {
        let queues = storageService.loadQueues()
        totalQueues = queues.count
        activeQueues = queues.filter { $0.isAutoUpdateEnabled }.count
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func checkForUpdatesNow() {
        Task {
            let queues = storageService.loadQueues()
            for queue in queues where queue.isAutoUpdateEnabled {
                do {
                    let scheduleData = try await APIService.shared.fetchSchedule(for: queue.queueNumber)
                    
                    if let jsonData = try? JSONEncoder().encode(scheduleData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        storageService.saveScheduleJSON(jsonString, for: queue.id)
                    }
                } catch {
                    print("Error updating \(queue.name): \(error)")
                }
            }
        }
    }
    
    func deleteAllQueues() {
        storageService.saveQueues([])
        NotificationService.shared.cancelAllNotifications()
        updateStats()
    }
}

// MARK: - Preview
// #Preview {
//    SettingsView()
// }
