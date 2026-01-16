//
//  ScheduleView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
//

import SwiftUI

// MARK: - Schedule View
struct ScheduleView: View {
    let queue: PowerQueue
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ScheduleViewModel
    @State private var showDetailedTimeline = false
    
    init(queue: PowerQueue) {
        self.queue = queue
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(queue: queue))
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
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.black)
                        Text("Завантаження...")
                            .font(.system(size: 16))
                            .foregroundColor(.black.opacity(0.6))
                    }
                } else if let scheduleData = viewModel.currentSchedule {
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
                // Банер попередження якщо дані з кешу
                if viewModel.isFromCache {
                    offlineBanner
                }
                
                // Шапка з назвою та перемикачем днів
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(queue.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Черга \(queue.queueNumber)")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        Spacer()
                    }
                    
                    // Перемикач днів (якщо є більше одного дня)
                    if viewModel.showDayPicker {
                        dayPickerSegment
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                infoCard(data)
                
                settingsCard
                
                timelineCard(data)
                
                shutdownsSection(data)
                
                totalTimeCard(data)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Offline Banner
    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "856404"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Немає з'єднання")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "856404"))
                
                Text("Показані дані можуть бути неактуальними")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "856404").opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                viewModel.fetchSchedule()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "856404"))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "FFF3CD"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "FFEEBA"), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Day Picker Segment (компактний стиль Дія)
    private var dayPickerSegment: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.availableDays) { day in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.selectedDay = day
                    }
                }) {
                    Text(day.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(viewModel.selectedDay == day ? .black : .black.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if viewModel.selectedDay == day {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                                }
                            }
                        )
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.06))
        )
    }
    
    // MARK: - Info Card
    private func infoCard(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Дата")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                    
                    HStack(spacing: 6) {
                        Text(data.eventDate)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("(\(viewModel.selectedDay.rawValue))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Оновлено")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                    Text(data.createdAt)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Затверджено з")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                    Text(data.scheduleApprovedSince)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Settings Card
    private var settingsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 20)
                
                Text("Сповіщення")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "4CAF50"))
            }
            .padding(16)
            
            Divider()
                .padding(.leading, 52)
            
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 20)
                
                Text("Автооновлення")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.autoUpdateEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "4CAF50"))
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Timeline Card
    private func timelineCard(_ data: ScheduleData) -> some View {
        Button(action: {
            showDetailedTimeline = true
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Візуалізація доби")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Показуємо який день + стрілка
                    HStack(spacing: 4) {
                        Text(viewModel.selectedDay.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black.opacity(0.3))
                    }
                }
                
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
                    
                    Spacer()
                    
                    Text("Детальніше")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 18)
        .sheet(isPresented: $showDetailedTimeline) {
            if let schedule = viewModel.currentSchedule {
                DetailedTimelineView(
                    scheduleData: schedule,
                    queueNumber: queue.queueNumber,
                    selectedDay: viewModel.selectedDay
                )
            }
        }
    }
    
    // MARK: - Shutdowns Section
    private func shutdownsSection(_ data: ScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Відключення")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(viewModel.selectedDay.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
            .padding(.horizontal, 16)
            
            if data.shutdowns.isEmpty {
                Text(emptyShutdownsText)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(data.shutdowns) { shutdown in
                        shutdownCard(shutdown)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Shutdowns Text
    private var emptyShutdownsText: String {
        switch viewModel.selectedDay {
        case .yesterday:
            return "Вчора відключень не було"
        case .today:
            return "Сьогодні відключень немає"
        case .tomorrow:
            return "Завтра відключень немає"
        }
    }
    
    // MARK: - Shutdown Card
    private func shutdownCard(_ shutdown: Shutdown) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 19))
                .foregroundColor(Color(hex: "FF5252"))
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(shutdown.shutdownHours)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                
                let hours = shutdown.durationMinutes / 60
                let minutes = shutdown.durationMinutes % 60
                
                Text("Тривалість: \(hours) год \(minutes) хв")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Total Time Card
    private func totalTimeCard(_ data: ScheduleData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 19))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Всього без світла (\(viewModel.selectedDay.rawValue.lowercased()))")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("\(data.totalHours) год \(data.remainingMinutes) хв")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
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

// MARK: - Detailed Timeline View
struct DetailedTimelineView: View {
    let scheduleData: ScheduleData
    let queueNumber: String
    let selectedDay: DayOption
    
    @Environment(\.dismiss) var dismiss
    
    // Поточний час
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private var currentMinute: Int {
        Calendar.current.component(.minute, from: Date())
    }
    
    // Чи показувати лінію поточного часу (тільки для сьогодні)
    private var showCurrentTimeLine: Bool {
        selectedDay == .today
    }
    
    // Висота однієї години
    private let hourHeight: CGFloat = 60
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон в стилі додатку
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
                    // Заголовок
                    headerView
                    
                    // Номер черги
                    Text("Черга \(queueNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                    
                    // Графік
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Картка з графіком
                                ZStack(alignment: .topLeading) {
                                    // Сітка годин
                                    hoursGrid
                                    
                                    // Блоки відключень
                                    shutdownBlocks
                                    
                                    // Лінія поточного часу
                                    if showCurrentTimeLine {
                                        currentTimeLine
                                    }
                                }
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.85))
                                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                                )
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 100)
                        }
                        .onAppear {
                            // Скролимо до поточного часу
                            if showCurrentTimeLine {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Підсумок внизу
                    summaryFooter
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Назад")
                        .font(.system(size: 16))
                }
                .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Графік вимкнень")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            // День
            Text(selectedDay.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
    
    // MARK: - Hours Grid
    private var hoursGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<25, id: \.self) { hour in
                HStack(spacing: 0) {
                    // Час зліва
                    Text(String(format: "%02d:00", hour == 24 ? 0 : hour))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                        .frame(width: 45, alignment: .leading)
                    
                    // Лінія
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
        .padding(.leading, 12)
    }
    
    // MARK: - Shutdown Blocks
    private var shutdownBlocks: some View {
        ZStack(alignment: .topLeading) {
            ForEach(scheduleData.shutdowns) { shutdown in
                shutdownBlock(shutdown)
            }
        }
        .padding(.leading, 57)
        .padding(.trailing, 12)
    }
    
    private func shutdownBlock(_ shutdown: Shutdown) -> some View {
        let startMinutes = parseTimeToMinutes(shutdown.from)
        let endMinutes = parseTimeToMinutes(shutdown.to)
        
        // Обробка переходу через північ
        let adjustedEndMinutes = endMinutes <= startMinutes ? endMinutes + 24 * 60 : endMinutes
        let duration = adjustedEndMinutes - startMinutes
        
        let topOffset = CGFloat(startMinutes) / 60.0 * hourHeight
        let height = CGFloat(duration) / 60.0 * hourHeight
        
        let hours = duration / 60
        let minutes = duration % 60
        let durationText = minutes > 0 ? "\(hours) год \(minutes) хв" : "\(hours) год"
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 12))
                Text(durationText)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.top, 8)
            .padding(.leading, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(height, 30))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "FF5252"))
        )
        .offset(y: topOffset)
    }
    
    // MARK: - Current Time Line
    private var currentTimeLine: some View {
        let totalMinutes = currentHour * 60 + currentMinute
        let topOffset = CGFloat(totalMinutes) / 60.0 * hourHeight
        
        return HStack(spacing: 0) {
            // Час в кружечку
            Text(String(format: "%02d:%02d", currentHour, currentMinute))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color(hex: "FF9500")))
            
            // Лінія
            Rectangle()
                .fill(Color(hex: "FF9500"))
                .frame(height: 2)
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .offset(y: topOffset)
    }
    
    // MARK: - Summary Footer
    private var summaryFooter: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "FF5252"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Всього без світла")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("\(scheduleData.totalHours) год \(scheduleData.remainingMinutes) хв")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            Color.white.opacity(0.95)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Helper
    private func parseTimeToMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}
