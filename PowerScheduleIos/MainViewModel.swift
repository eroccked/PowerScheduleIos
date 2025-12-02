//
//  MainViewModel.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
import Foundation
import SwiftUI

// MARK: - Main View Model
@MainActor
class MainViewModel: ObservableObject {
    @Published var queues: [PowerQueue] = []
    @Published var updateInterval: Int = 15
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let storageService = StorageService.shared
    private let apiService = APIService.shared
    
    init() {
        loadQueues()
        loadUpdateInterval()
        startBackgroundUpdates()
    }
    
    // MARK: - Load Data
    func loadQueues() {
        queues = storageService.loadQueues()
    }
    
    func loadUpdateInterval() {
        updateInterval = storageService.loadUpdateInterval()
    }
    
    // MARK: - Add Queue
    func addQueue(name: String, queueNumber: String) {
        guard !name.isEmpty else {
            showErrorAlert("❌ Введіть назву!")
            return
        }
        
        guard !queueNumber.isEmpty else {
            showErrorAlert("❌ Введіть чергу!")
            return
        }
        
        guard isValidQueueFormat(queueNumber) else {
            showErrorAlert("❌ Невірний формат черги! Приклад: 5.2")
            return
        }
        
        let newQueue = PowerQueue(
            name: name,
            queueNumber: queueNumber
        )
        
        storageService.addQueue(newQueue)
        loadQueues()
    }
    
    // MARK: - Delete Queue
    func deleteQueue(_ queue: PowerQueue) {
        storageService.deleteQueue(queue)
        loadQueues()
    }
    
    // MARK: - Update Queue
    func updateQueue(_ queue: PowerQueue) {
        storageService.updateQueue(queue)
        loadQueues()
    }
    
    // MARK: - Check for Updates
    func checkForUpdatesNow() {
        Task {
            for queue in queues where queue.isAutoUpdateEnabled {
                await checkQueueForChanges(queue)
            }
        }
    }
    
    private func checkQueueForChanges(_ queue: PowerQueue) async {
        do {
            let scheduleData = try await apiService.fetchSchedule(for: queue.queueNumber)
            
            if let jsonData = try? JSONEncoder().encode(scheduleData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                let savedJSON = storageService.loadScheduleJSON(for: queue.id)
                
                if savedJSON != jsonString {
                    storageService.saveScheduleJSON(jsonString, for: queue.id)
                    
                    if savedJSON != nil {
                        await showUpdateNotification(for: queue)
                    }
                }
            }
        } catch {
            print("Error checking queue \(queue.name): \(error)")
        }
    }
    
    // MARK: - Background Updates
    private func startBackgroundUpdates() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(updateInterval * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForUpdatesNow()
            }
        }
    }
    
    // MARK: - Validation
    private func isValidQueueFormat(_ queue: String) -> Bool {
        let pattern = "^\\d+\\.\\d+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: queue.utf16.count)
        return regex?.firstMatch(in: queue, range: range) != nil
    }
    
    // MARK: - Notifications
    private func showUpdateNotification(for queue: PowerQueue) async {
        print("📊 Графік оновлено для \(queue.name)")
    }
    
    // MARK: - Alerts
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Add Queue View (Redesign у стилі Дія)
struct AddQueueView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MainViewModel
    
    @State private var name = ""
    @State private var mainQueue = 1
    @State private var subQueue = 1
    
    var queueNumber: String {
        "\(mainQueue).\(subQueue)"
    }
    
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
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Нова черга")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Додайте інформацію про вашу чергу відключень")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Назва")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.horizontal, 22)
                                
                                VStack(spacing: 0) {
                                    TextField("Квартира, Офіс, Дача", text: $name)
                                        .font(.system(size: 15))
                                        .foregroundColor(.black)
                                        .padding(16)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.85))
                                        .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
                                )
                                .padding(.horizontal, 18)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Черга")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.6))
                                    .padding(.horizontal, 22)
                                
                                VStack(spacing: 16) {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        
                                        Picker("", selection: $mainQueue) {
                                            ForEach(1...10, id: \.self) { number in
                                                Text("\(number)")
                                                    .font(.system(size: 28, weight: .semibold))
                                                    .foregroundColor(.black)
                                                    .tag(number)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 70)
                                        
                                        Text(".")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Picker("", selection: $subQueue) {
                                            ForEach(1...10, id: \.self) { number in
                                                Text("\(number)")
                                                    .font(.system(size: 28, weight: .semibold))
                                                    .foregroundColor(.black)
                                                    .tag(number)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 70)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    
                                    VStack(spacing: 6) {
                                        Text("Обрана черга:")
                                            .font(.system(size: 13))
                                            .foregroundColor(.black.opacity(0.6))
                                        
                                        Text(queueNumber)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                    .padding(.bottom, 8)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.85))
                                        .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
                                )
                                .padding(.horizontal, 18)
                            }
                            
                            HStack(spacing: 9) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black.opacity(0.4))
                                
                                Text("Номер черги можна знайти в квитанції або на сайті вашого електропостачальника")
                                    .font(.system(size: 11))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.5))
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 18)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.addQueue(name: name, queueNumber: queueNumber)
                        if viewModel.queues.contains(where: { $0.name == name }) {
                            dismiss()
                        }
                    }) {
                        Text("Додати чергу")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.85))
                                    .shadow(color: Color.black.opacity(0.1), radius: 7, x: 0, y: 2)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Скасувати")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                    }
                }
            }
        }
    }
}
