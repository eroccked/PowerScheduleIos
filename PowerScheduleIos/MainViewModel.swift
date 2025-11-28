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

// MARK: - Add Queue View
struct AddQueueView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MainViewModel
    
    @State private var name = ""
    @State private var queueNumber = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Інформація про чергу")) {
                    TextField("Назва (наприклад: Квартира, Офіс)", text: $name)
                    TextField("Черга (наприклад: 5.2)", text: $queueNumber)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(action: {
                        viewModel.addQueue(name: name, queueNumber: queueNumber)
                        if viewModel.queues.contains(where: { $0.name == name }) {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("➕ ДОДАТИ ЧЕРГУ")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(hex: "4CAF50"))
                }
            }
            .navigationTitle("Нова черга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") {
                        dismiss()
                    }
                }
            }
        }
    }
}
