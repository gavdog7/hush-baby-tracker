import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var baby: Baby?
    @State private var settings: BabySettings = BabySettings()
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false

    // Notification settings
    @State private var bottleExpiryNotifications = true
    @State private var wakeWindowNotifications = false
    @State private var feedingDueNotifications = false
    @State private var quietHoursEnabled = true
    @State private var quietHoursStart = 22
    @State private var quietHoursEnd = 6

    var body: some View {
        NavigationStack {
            Form {
                // Baby info section
                if let baby = baby {
                    Section("Baby") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(baby.name)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Age")
                            Spacer()
                            Text(baby.ageDisplay)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Birth Date")
                            Spacer()
                            Text(baby.birthDate, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Formula settings
                Section("Formula Settings") {
                    Stepper(
                        "Default bottle: \(String(format: "%.1f", settings.defaultBottleSizeOz)) oz",
                        value: $settings.defaultBottleSizeOz,
                        in: 1...12,
                        step: 0.5
                    )

                    Stepper(
                        "Refrigerated expiry: \(settings.refrigeratedExpiryHours)h",
                        value: $settings.refrigeratedExpiryHours,
                        in: 1...24
                    )

                    Toggle("Use metric units (ml)", isOn: $settings.useMetricUnits)
                }

                // Notification settings
                Section("Notifications") {
                    Toggle("Bottle expiry (15 min warning)", isOn: $bottleExpiryNotifications)
                    Toggle("Wake window alerts", isOn: $wakeWindowNotifications)
                    Toggle("Feeding due (3h since last)", isOn: $feedingDueNotifications)
                }

                Section("Quiet Hours") {
                    Toggle("Enable quiet hours", isOn: $quietHoursEnabled)

                    if quietHoursEnabled {
                        HStack {
                            Text("From")
                            Spacer()
                            Picker("Start", selection: $quietHoursStart) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(formatHour(hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Text("Until")
                            Spacer()
                            Picker("End", selection: $quietHoursEnd) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(formatHour(hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    NavigationLink("Dark Mode") {
                        DarkModeSettingsView()
                    }
                }

                // Account
                Section("Account") {
                    if let user = authService.currentUser {
                        HStack {
                            Text("Signed in as")
                            Spacer()
                            Text(user.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirmation = true
                    }
                }

                // Data management
                Section("Data") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }

                    Button("Delete All Data", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://hush.app/privacy")!)

                    Link("Terms of Service", destination: URL(string: "https://hush.app/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .task {
                loadData()
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your baby's data. This action cannot be undone.")
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour

        guard let date = Calendar.current.date(from: components) else {
            return "\(hour):00"
        }

        return formatter.string(from: date)
    }

    private func loadData() {
        let babyRepo = BabyRepository()
        baby = try? babyRepo.fetchFirstBaby()

        if let baby = baby {
            settings = baby.settings
        }
    }

    private func saveSettings() {
        guard var updatedBaby = baby else { return }

        updatedBaby.settings = settings

        let babyRepo = BabyRepository()
        _ = try? babyRepo.update(updatedBaby)
    }

    private func deleteAllData() {
        guard let baby = baby else { return }

        let babyRepo = BabyRepository()
        try? babyRepo.delete(baby)

        authService.signOut()
        dismiss()
    }
}

// MARK: - Dark Mode Settings

struct DarkModeSettingsView: View {
    @AppStorage("darkModePreference") private var darkModePreference = 0

    var body: some View {
        List {
            Picker("Appearance", selection: $darkModePreference) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .navigationTitle("Dark Mode")
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @State private var dateRange = 1  // 0=24h, 1=7d, 2=30d, 3=all
    @State private var isExporting = false
    @State private var exportedData: String?
    @State private var showShareSheet = false

    var body: some View {
        List {
            Section("Date Range") {
                Picker("Range", selection: $dateRange) {
                    Text("Last 24 hours").tag(0)
                    Text("Last 7 days").tag(1)
                    Text("Last 30 days").tag(2)
                    Text("All time").tag(3)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Button(action: exportData) {
                    if isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Export as CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isExporting)
            }

            if let data = exportedData {
                Section("Preview") {
                    Text(data)
                        .font(.caption)
                        .fontDesign(.monospaced)
                }
            }
        }
        .navigationTitle("Export Data")
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
    }

    private func exportData() {
        isExporting = true

        // TODO: Implement actual CSV export
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exportedData = """
            date,time,event_type,duration_minutes,amount_prepared_oz,amount_consumed_oz,diaper_contents,logged_by,notes
            2026-01-03,08:30,eat,15,4.0,3.5,,Demo User,
            2026-01-03,09:00,sleep,90,,,,Demo User,Morning nap
            2026-01-03,10:30,diaper,,,wet,,Demo User,
            """
            isExporting = false
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(AuthService())
}
