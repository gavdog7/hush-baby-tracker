import SwiftUI

struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @State private var babyName = ""
    @State private var birthDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onComplete: (Baby) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.pink)

                        Text("Welcome to Hush!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Let's add your baby to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                Section("Baby's Information") {
                    TextField("Baby's name", text: $babyName)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    DatePicker(
                        "Birth date",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                Section {
                    Button(action: createBaby) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(babyName.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Baby")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func createBaby() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "Please sign in first"
            return
        }

        isLoading = true

        let baby = Baby(
            name: babyName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            primaryCaregiverId: userId
        )

        let babyRepo = BabyRepository()

        do {
            let createdBaby = try babyRepo.create(baby)

            // Add user as primary caregiver
            try babyRepo.addCaregiver(
                babyId: createdBaby.id,
                userId: userId,
                role: .primary
            )

            isLoading = false
            onComplete(createdBaby)
        } catch {
            isLoading = false
            errorMessage = "Failed to add baby: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingView { baby in
        print("Created baby: \(baby.name)")
    }
    .environment(AuthService())
}
