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
        VStack(spacing: 24) {
            Text("Попереджати за")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 40)
            
            Text("Виберіть за скільки часу ви хочете отримати сповіщення перед відключенням")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 0) {
                Spacer()
                
                Picker("", selection: $selectedHours) {
                    ForEach(0...5, id: \.self) { hour in
                        Text("\(hour)")
                            .font(.system(size: 32))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                
                Text("год")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                
                Picker("", selection: $selectedMinutes) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                        Text("\(minute)")
                            .font(.system(size: 32))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                
                Text("хв")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "F5F5F5"))
            )
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Приклад сповіщення:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("⚡ Скоро відключення!")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(getExampleText())
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                let totalMinutes = selectedHours * 60 + selectedMinutes
                viewModel.notificationMinutes = totalMinutes > 0 ? totalMinutes : 5 // Мінімум 5 хв
                dismiss()
            }) {
                Text("Зберегти")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "1976D2"))
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Час попередження")
        .navigationBarTitleDisplayMode(.inline)
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
