import SwiftUI

struct BusinessProfileView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @Environment(\.openURL) private var openURL
    @State private var didShowCheckInConfirmation = false
    @State private var isShowingConsentSheet = false

    // Per-category intent state. Defaults chosen so Quick Check-In works with
    // zero additional taps for the common path.
    @State private var vetReason: String = ""
    @State private var vetUrgency: BusinessProfile.VetUrgency = .routine
    @State private var daycareDate: Date = Date()
    @State private var groomingService: BusinessProfile.GroomingService = .fullGroom
    @State private var groomingDate: Date = Date()
    @State private var boardingCheckIn: Date = Date()
    @State private var boardingCheckOut: Date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()

    let business: BusinessProfile

    var body: some View {
        let availability = discoveryStore.availability(for: business)
        List {
            Section("Business") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(business.name)
                            .font(.title3.bold())
                        Spacer()
                        Text("\(business.category.rawValue) · \(business.listingType.rawValue)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                    Text(business.summary)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label(business.partnershipStatus.label, systemImage: business.partnershipStatus == .partner ? "checkmark.seal.fill" : "mappin")
                            .foregroundStyle(business.partnershipStatus == .partner ? OmniPetColor.emerald : OmniPetColor.grayPin)
                        Label(String(format: "%.1f mi", business.distanceMiles), systemImage: "location")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            }

            visitIntentSection

            Section(availability.requirementsAreAdvisory ? "Records (advisory)" : "Requirements Checklist") {
                if availability.requirementsAreAdvisory {
                    Text("Vets typically administer these — we'll send whatever you have and flag gaps to the clinic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(business.requirements, id: \.self) { requirement in
                    let missing = availability.missingRequirements.contains(requirement)
                    let expired = availability.expiredRequirements.contains(requirement)
                    Label(requirement, systemImage: expired ? "clock.badge.exclamationmark" : (missing ? "exclamationmark.circle" : "checkmark.circle"))
                        .foregroundStyle(expired ? OmniPetColor.warning : (missing ? OmniPetColor.warning : .primary))
                }
            }

            if !availability.isReadyForCheckIn {
                Section("Gaps Identified") {
                    Text("Add or refresh records in Vault before check-in can be completed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(availability.missingRequirements, id: \.self) { requirement in
                        Label("Missing: \(requirement)", systemImage: "xmark.circle")
                            .foregroundStyle(OmniPetColor.danger)
                    }
                    ForEach(availability.expiredRequirements, id: \.self) { requirement in
                        Label("Expired: \(requirement)", systemImage: "clock.badge.xmark")
                            .foregroundStyle(OmniPetColor.danger)
                    }
                    Button("Fix in Vault") {
                        discoveryStore.selectedTab = .vault
                    }
                }
            }

            Section("Handshake") {
                Button("Check-In with Vault") {
                    isShowingConsentSheet = true
                }
                .disabled(!availability.isReadyForCheckIn)
                .buttonStyle(.borderedProminent)
                Button("Call Business") {
                    guard
                        let number = business.phoneNumber,
                        let url = URL(string: "tel://\(number)")
                    else { return }
                    openURL(url)
                }
                .disabled(business.phoneNumber == nil)
                Button("Open Website") {
                    guard let url = business.websiteURL else { return }
                    openURL(url)
                }
                .disabled(business.websiteURL == nil)
            }
        }
        .navigationTitle("Business Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    discoveryStore.toggleFavorite(business.name)
                } label: {
                    Image(systemName: discoveryStore.isFavorite(business.name) ? "star.fill" : "star")
                        .foregroundStyle(discoveryStore.isFavorite(business.name) ? OmniPetColor.warning : .secondary)
                }
            }
        }
        .alert("Check-in sent", isPresented: $didShowCheckInConfirmation) {
            Button("View in Activity") {
                discoveryStore.selectedTab = .activity
            }
            Button("Stay Here", role: .cancel) { }
        } message: {
            Text("Your Vault packet was logged. View it in Activity to track status.")
        }
        .sheet(isPresented: $isShowingConsentSheet) {
            ShareConsentSheet(
                business: business,
                petName: discoveryStore.petPass.petName,
                documents: discoveryStore.documents
            ) { titles, durationLabel in
                discoveryStore.checkIn(
                    with: business,
                    intent: currentIntent(),
                    sharedDocumentTitles: titles,
                    shareDurationLabel: durationLabel
                )
                isShowingConsentSheet = false
                didShowCheckInConfirmation = true
            } onCancel: {
                isShowingConsentSheet = false
            }
        }
    }

    @ViewBuilder
    private var visitIntentSection: some View {
        switch business.category {
        case .vet:
            Section("Visit Details") {
                Picker("Urgency", selection: $vetUrgency) {
                    ForEach(BusinessProfile.VetUrgency.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Reason for visit (e.g. limping, annual exam)", text: $vetReason, axis: .vertical)
                    .lineLimit(1...3)
            }
        case .daycare:
            Section("Visit Details") {
                DatePicker("Day of stay", selection: $daycareDate, in: Date()..., displayedComponents: .date)
            }
        case .grooming:
            Section("Visit Details") {
                Picker("Service", selection: $groomingService) {
                    ForEach(BusinessProfile.GroomingService.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Appointment", selection: $groomingDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
            }
        case .boarding:
            Section("Visit Details") {
                DatePicker("Check-in", selection: $boardingCheckIn, in: Date()..., displayedComponents: .date)
                DatePicker("Check-out", selection: $boardingCheckOut, in: boardingCheckIn..., displayedComponents: .date)
                if business.listingType == .individual {
                    Text("Individual host — expect a direct message reply rather than an instant booking.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func currentIntent() -> BusinessProfile.VisitIntent {
        switch business.category {
        case .vet: return .vet(reason: vetReason, urgency: vetUrgency)
        case .daycare: return .daycare(date: daycareDate)
        case .grooming: return .grooming(service: groomingService, date: groomingDate)
        case .boarding: return .boarding(checkIn: boardingCheckIn, checkOut: boardingCheckOut)
        }
    }
}

struct ShareConsentSheet: View {
    enum ShareDuration: String, CaseIterable, Identifiable {
        case oneDay = "24 hours"
        case sevenDays = "7 days"
        case thirtyDays = "30 days"
        var id: String { rawValue }
    }

    let business: BusinessProfile
    let petName: String
    let documents: [VaultDocument]
    let onConfirm: ([String], String) -> Void
    let onCancel: () -> Void

    @State private var requiredSelections: [UUID: Bool] = [:]
    @State private var optionalSelections: [UUID: Bool] = [:]
    @State private var showOptional: Bool = false
    @State private var duration: ShareDuration = .oneDay

    private var requirementKeys: Set<String> {
        Set(business.requirements.map { $0.lowercased() })
    }

    private var requiredDocuments: [VaultDocument] {
        documents.filter { requirementKeys.contains($0.normalizedTitle) }
    }

    private var optionalDocuments: [VaultDocument] {
        documents.filter { !requirementKeys.contains($0.normalizedTitle) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sharing \(petName)'s Vault with")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(business.name)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                Section("Documents to share") {
                    if business.category == .vet {
                        Label("Vet requirements are advisory — you can share what you have. The clinic will handle the rest.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if requiredDocuments.isEmpty {
                        Text("No matching required documents in Vault.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(requiredDocuments) { doc in
                            Toggle(isOn: bindingFor(doc, isRequired: true)) {
                                VStack(alignment: .leading) {
                                    Text(doc.title)
                                    Text(doc.expirationText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !optionalDocuments.isEmpty {
                    Section {
                        DisclosureGroup("Include optional documents", isExpanded: $showOptional) {
                            ForEach(optionalDocuments) { doc in
                                Toggle(isOn: bindingFor(doc, isRequired: false)) {
                                    VStack(alignment: .leading) {
                                        Text(doc.title)
                                        Text(doc.expirationText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Share duration") {
                    Picker("Access expires after", selection: $duration) {
                        ForEach(ShareDuration.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                }

                Section {
                    Button("Confirm and Share") {
                        onConfirm(selectedTitles(), duration.rawValue)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Share Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .onAppear { primeDefaults() }
        }
    }

    private func bindingFor(_ doc: VaultDocument, isRequired: Bool) -> Binding<Bool> {
        Binding(
            get: {
                if isRequired { return requiredSelections[doc.id] ?? true }
                return optionalSelections[doc.id] ?? false
            },
            set: { newValue in
                if isRequired { requiredSelections[doc.id] = newValue }
                else { optionalSelections[doc.id] = newValue }
            }
        )
    }

    private func primeDefaults() {
        for doc in requiredDocuments where requiredSelections[doc.id] == nil {
            requiredSelections[doc.id] = true
        }
        for doc in optionalDocuments where optionalSelections[doc.id] == nil {
            optionalSelections[doc.id] = false
        }
    }

    private func selectedTitles() -> [String] {
        var titles: [String] = []
        for doc in requiredDocuments where (requiredSelections[doc.id] ?? true) {
            titles.append(doc.title)
        }
        for doc in optionalDocuments where (optionalSelections[doc.id] ?? false) {
            titles.append(doc.title)
        }
        return titles
    }
}
