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
                // Градієнт у стилі Дія
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
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.black)
                        Text("Завантаження...")
                            .font(.system(size: 16))
                            .foregroundColor(.black.opacity(0.6))
                    }
                } else if let scheduleData = viewModel.scheduleData {
                    scheduleContent(scheduleData)
                } else if viewModel.errorMessage != nil {
                    errorView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Назад")
                        }
                        .foregroundColor(.black)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.fetchSchedule()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
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
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(queue.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Черга \(queue.queueNumber)")
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                
                infoCard(data)
                
                settingsCard
                
                timelineCard(data)
                
                shutdownsSection(data)
                
                totalTimeCard(data)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Info Card
    private func infoCard(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Дата")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.5))
                    Text(data.eventDate)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Оновлено")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.5))
                    Text(data.createdAt)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 22)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Затверджено з")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.5))
                    Text(data.scheduleApprovedSince)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
        )
        .padding(.horizontal, 18)
    }
    
    // MARK: - Settings Card
    private var settingsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 22)
                
                Text("Сповіщення")
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "4CAF50"))
            }
            .padding(18)
            
            Divider()
                .padding(.leading, 58)
            
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .frame(width: 22)
                
                Text("Автооновлення")
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.autoUpdateEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "4CAF50"))
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
        )
        .padding(.horizontal, 18)
    }
    
    // MARK: - Timeline Card
    private func timelineCard(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Візуалізація доби")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
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
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.black.opacity(0.5))
            
            HStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Rectangle()
                        .fill(data.hourlyTimeline[hour] ?
                              Color(hex: "4CAF50") :
                              Color(hex: "FF5252"))
                        .frame(height: 45)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            
            HStack(spacing: 20) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(hex: "4CAF50"))
                        .frame(width: 11, height: 11)
                    Text("Світло є")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.7))
                }
                
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(hex: "FF5252"))
                        .frame(width: 11, height: 11)
                    Text("Відключення")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
        )
        .padding(.horizontal, 18)
    }
    
    // MARK: - Shutdowns Section
    private func shutdownsSection(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Відключення")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
            
            if data.shutdowns.isEmpty {
                Text("Сьогодні відключень немає")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
                    )
                    .padding(.horizontal, 18)
            } else {
                VStack(spacing: 10) {
                    ForEach(data.shutdowns) { shutdown in
                        shutdownCard(shutdown)
                    }
                }
            }
        }
    }
    
    // MARK: - Shutdown Card
    private func shutdownCard(_ shutdown: Shutdown) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 21))
                .foregroundColor(Color(hex: "FF5252"))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(shutdown.shutdownHours)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                let hours = shutdown.durationMinutes / 60
                let minutes = shutdown.durationMinutes % 60
                
                Text("Тривалість: \(hours) год \(minutes) хв")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 18)
    }
    
    // MARK: - Total Time Card
    private func totalTimeCard(_ data: ScheduleData) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 21))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Всього без світла")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("\(data.totalHours) год \(data.remainingMinutes) хв")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
        )
        .padding(.horizontal, 18)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundColor(Color(hex: "FF5252"))
            
            Text(viewModel.errorMessage ?? "Помилка завантаження")
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            Button(action: {
                viewModel.fetchSchedule()
            }) {
                Text("Спробувати ще раз")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
            }
        }
    }
}

// MARK: - Preview
// #Preview {
//     ScheduleView(queue: PowerQueue(name: "Тестова", queueNumber: "5.2"))
// }
