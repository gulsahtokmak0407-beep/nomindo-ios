import SwiftUI

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingAddAlarm = false
    @State private var selectedDate = Date()
    @State private var alarmLabel = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // Header & Streak Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NOMINDO")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("ERTELEME YOK. BAHANE YOK.")
                                    .font(.caption.bold())
                                    .tracking(1.5)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("🔥 \(alarmManager.streakCount)")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("GÜN SERİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Instant Test Button
                        Button(action: {
                            alarmManager.triggerAlarm(title: "ANINDA DİSİPLİN TESTİ")
                        }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .font(.title3)
                                Text("ALARMI VE AI KAMERAYI ŞİMDİ TEST ET")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)

                        // Alarms List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ANTRENMAN ALARMLARI")
                                    .font(.caption.bold())
                                    .tracking(1.2)
                                    .foregroundColor(.gray)
                                Spacer()
                                Button(action: { showingAddAlarm = true }) {
                                    Label("Yeni Ekle", systemImage: "plus.circle.fill")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.orange)
                                }
                            }

                            if alarmManager.alarms.isEmpty {
                                Text("Henüz alarm eklenmedi. Sağ üstten yeni bir spor alarmı kur.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(alarmManager.alarms) { alarm in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(alarm.formattedTime)
                                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                                .foregroundColor(alarm.isEnabled ? .white : .gray)
                                            Text(alarm.label)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Toggle("", isOn: Binding(
                                            get: { alarm.isEnabled },
                                            set: { _ in alarmManager.toggleAlarm(alarm) }
                                        ))
                                        .labelsHidden()
                                        .tint(.orange)
                                    }
                                    .padding(18)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                NavigationStack {
                    Form {
                        DatePicker("Alarm Saati", selection: $selectedDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                        TextField("Antrenman Adı (Örn: Sabah Kardiyo)", text: $alarmLabel)
                    }
                    .navigationTitle("Yeni Spor Alarmı")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("İptal") { showingAddAlarm = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Kaydet") {
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                                alarmManager.addAlarm(
                                    hour: comps.hour ?? 8,
                                    minute: comps.minute ?? 0,
                                    label: alarmLabel
                                )
                                alarmLabel = ""
                                showingAddAlarm = false
                            }
                            .bold()
                            .foregroundColor(.orange)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $alarmManager.isAlarmRinging) {
                AlarmLockScreenView()
                    .environmentObject(alarmManager)
                    .interactiveDismissDisabled(true)
            }
        }
    }
}
