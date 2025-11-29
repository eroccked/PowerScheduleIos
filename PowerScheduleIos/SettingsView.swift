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
            Form {
                Section(header: Text("Про додаток")) {
                    HStack {
                        Text("💡")
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Графік Світла")
                                .font(.system(size: 18, weight: .bold))
                            Text("Версія 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Автооновлення")) {
                    Picker("Інтервал оновлення", selection: $viewModel.updateInterval) {
                        Text("5 хвилин").tag(5)
                        Text("10 хвилин").tag(10)
                        Text("15 хвилин").tag(15)
                        Text("30 хвилин").tag(30)
                        Text("60 хвилин").tag(60)
                    }
                    
                    Text("Додаток буде перевіряти оновлення графіків кожні \(viewModel.updateInterval) хвилин")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Сповіщення")) {
                    Toggle("Дозволити сповіщення", isOn: $viewModel.notificationsEnabled)
                    
                    if viewModel.notificationsEnabled {
                        NavigationLink(destination: NotificationTimePickerView(viewModel: viewModel)) {
                            HStack {
                                Text("⏰ Попереджати за")
                                Spacer()
                                Text(viewModel.notificationTimeText)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("✅ Ви отримуватимете сповіщення за \(viewModel.notificationTimeText) до відключення")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "4CAF50"))
                    } else {
                        Text("⚠️ Увімкніть дозвіл у налаштуваннях iOS")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
                
                Section(header: Text("Статистика")) {
                    HStack {
                        Text("Всього черг")
                        Spacer()
                        Text("\(viewModel.totalQueues)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Активних оновлень")
                        Spacer()
                        Text("\(viewModel.activeQueues)")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.checkForUpdatesNow()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Оновити всі графіки зараз")
                        }
                    }
                    
                    Button(action: {
                        viewModel.openNotificationSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Налаштування сповіщень iOS")
                        }
                    }
                }
                
                Section(header: Text("Небезпечна зона")) {
                    Button(role: .destructive, action: {
                        viewModel.showDeleteAllAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Видалити всі черги")
                        }
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://be-svitlo.oe.if.ua")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Джерело даних")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                        }
                    }
                }
            }
            .navigationTitle("Налаштування")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
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
                        
                        let savedJSON = storageService.loadScheduleJSON(for: queue.id)
                        
                        if savedJSON != jsonString {
                            storageService.saveScheduleJSON(jsonString, for: queue.id)
                            
                            if savedJSON != nil {
                                await NotificationService.shared.showScheduleUpdateNotification(queueName: queue.name)
                            }
                        }
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
//#Preview {
//    SettingsView()
//}
