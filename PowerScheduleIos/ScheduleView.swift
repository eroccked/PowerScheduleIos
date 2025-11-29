//
//  ScheduleView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//

import SwiftUI

// MARK: - Schedule View
struct ScheduleView: View {
    let queue: PowerQueue
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ScheduleViewModel
    
    init(queue: PowerQueue) {
        self.queue = queue
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(queue: queue))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5F5")
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                } else if let scheduleData = viewModel.scheduleData {
                    scheduleContent(scheduleData)
                } else if viewModel.errorMessage != nil {
                    errorView
                }
            }
            .navigationTitle("\(queue.name) (\(queue.queueNumber))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Назад") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Оновити") {
                        viewModel.fetchSchedule()
                    }
                }
            }
            .onAppear {
                viewModel.fetchSchedule()
            }
        }
    }
    
    // MARK: - Schedule Content
    @ViewBuilder
    private func scheduleContent(_ data: ScheduleData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                infoCard(data)
                
                togglesCard
                
                shutdownsSection(data)
                
                totalTimeCard(data)
                
                timelineCard(data)
            }
            .padding()
        }
    }
    
    // MARK: - Info Card
    private func infoCard(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📅 \(data.eventDate)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "212121"))
            
            Text("Оновлено: \(data.createdAt)")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "757575"))
            
            Text("Затверджено з: \(data.scheduleApprovedSince)")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "757575"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
    
    // MARK: - Toggles Card
    private var togglesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🔔 Нагадувати за 30 хв")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "424242"))
                Spacer()
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
            }
            .padding()
            .background(Color(hex: "FFF3E0"))
            .cornerRadius(12)
            
            HStack {
                Text("🔄 Автооновлення графіка")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "424242"))
                Spacer()
                Toggle("", isOn: $viewModel.autoUpdateEnabled)
                    .labelsHidden()
            }
            .padding()
            .background(Color(hex: "E8F5E9"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Shutdowns Section
    private func shutdownsSection(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ ВІДКЛЮЧЕННЯ:")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "F44336"))
            
            ForEach(data.shutdowns) { shutdown in
                shutdownCard(shutdown)
            }
        }
    }
    
    // MARK: - Shutdown Card
    private func shutdownCard(_ shutdown: Shutdown) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🕐 \(shutdown.shutdownHours)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "F44336"))
            
            let hours = shutdown.durationMinutes / 60
            let minutes = shutdown.durationMinutes % 60
            
            Text("   (\(hours) год \(minutes) хв)")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "757575"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
    
    // MARK: - Total Time Card
    private func totalTimeCard(_ data: ScheduleData) -> some View {
        Text("📊 ВСЬОГО: \(data.totalHours) год \(data.remainingMinutes) хв без світла")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color(hex: "1565C0"))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "BBDEFB"))
            .cornerRadius(12)
    }
    
    // MARK: - Timeline Card
    private func timelineCard(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 ВІЗУАЛІЗАЦІЯ (24 ГОДИНИ):")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "1976D2"))
            
            HStack {
                Text("0")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("6")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("12")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("18")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("24")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 10))
            .foregroundColor(Color(hex: "757575"))
            
            HStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Rectangle()
                        .fill(data.hourlyTimeline[hour] ?
                              Color(hex: "4CAF50") :
                              Color(hex: "F44336"))
                        .frame(height: 40)
                }
            }
            .cornerRadius(4)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(hex: "4CAF50"))
                        .frame(width: 20, height: 20)
                    Text("- світло є")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "757575"))
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(hex: "F44336"))
                        .frame(width: 20, height: 20)
                    Text("- відключення")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "757575"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "F44336"))
            
            Text(viewModel.errorMessage ?? "Помилка завантаження")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "424242"))
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.fetchSchedule()
            }) {
                Text("Спробувати ще раз")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "1976D2"))
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Preview
//#Preview {
//    ScheduleView(queue: PowerQueue(name: "Тестова", queueNumber: "5.2"))
//}
