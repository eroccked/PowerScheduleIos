//
//  NotificationTimePickerView.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 29.11.2025.
//

import SwiftUI

// MARK: - Notification Time Picker View
struct NotificationTimePickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        let totalMinutes = viewModel.notificationMinutes
        _selectedHours = State(initialValue: totalMinutes / 60)
        _selectedMinutes = State(initialValue: totalMinutes % 60)
    }
    
    var body: some View {
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
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Попереджати за")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Виберіть за скільки часу отримати сповіщення перед відключенням")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 14) {
                    HStack(spacing: 0) {
                        Spacer()
                        
                        Picker("", selection: $selectedHours) {
                            ForEach(0...5, id: \.self) { hour in
                                Text("\(hour)")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.black)
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70)
                        
                        Text("год")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.horizontal, 10)
                        
                        Picker("", selection: $selectedMinutes) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                                Text("\(minute)")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.black)
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70)
                        
                        Text("хв")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.horizontal, 10)
                        
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.08), radius: 7, x: 0, y: 2)
                    )
                    .padding(.horizontal, 18)
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Приклад сповіщення:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 14) {
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 21))
                            .foregroundColor(Color(hex: "FF9500"))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("⚡️ Скоро відключення!")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text(getExampleText())
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
                }
                .padding(.horizontal, 18)
                
                Spacer()

                Button(action: {
                    let totalMinutes = selectedHours * 60 + selectedMinutes
                    viewModel.notificationMinutes = totalMinutes > 0 ? totalMinutes : 5
                    dismiss()
                }) {
                    Text("Зберегти")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.1), radius: 7, x: 0, y: 2)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
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
        }
    }
    
    // MARK: - Helper Functions
    private func getExampleText() -> String {
        let totalMins = selectedHours * 60 + selectedMinutes
        let timeText: String
        
        if totalMins >= 60 {
            let h = totalMins / 60
            let m = totalMins % 60
            if m == 0 {
                timeText = "через \(h) год"
            } else {
                timeText = "через \(h) год \(m) хв"
            }
        } else if totalMins > 0 {
            timeText = "через \(totalMins) хв"
        } else {
            timeText = "зараз"
        }
        
        return "Дім: відключення о 14:00 (\(timeText))"
    }
}

// MARK: - Preview
// #Preview {
//     NavigationStack {
//         NotificationTimePickerView(viewModel: SettingsViewModel())
//     }
// }
