import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var isPresentingScanner = false
    @State private var isPresentingAddDocument = false
    @State private var isPresentingSendRecords = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pet Pass") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(discoveryStore.petPass.petName)
                            .font(.title3.bold())
                        Text("\(discoveryStore.petPass.breed) · \(discoveryStore.petPass.ageDescription)")
                            .foregroundStyle(.secondary)
                        Picker("Species", selection: Binding(
                            get: { discoveryStore.petPass.species },
                            set: { discoveryStore.updateSpecies($0) }
                        )) {
                            ForEach(Species.allCases, id: \.self) { species in
                                Text(species.rawValue).tag(species)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text(discoveryStore.petPass.vaccineStatus.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(statusColor)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    if discoveryStore.documents.isEmpty {
                        VStack(spacing: 8) {
                            Text("No documents yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Add your pet's vaccine records, certificates, and other documents to get started.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(discoveryStore.documents) { document in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(document.title)
                                        .font(.headline)
                                    Spacer()
                                    if document.isExpired {
                                        Text("Expired")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(OmniPetColor.danger.opacity(0.15), in: Capsule())
                                            .foregroundStyle(OmniPetColor.danger)
                                    }
                                }
                                Text("\(document.type.rawValue) · \(document.expirationText)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            discoveryStore.deleteDocument(at: offsets)
                        }
                    }
                } header: {
                    HStack {
                        Text("Documents")
                        Spacer()
                        Button {
                            isPresentingAddDocument = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(OmniPetColor.emerald)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("Scan Document") {
                        isPresentingScanner = true
                    }
                    .buttonStyle(.bordered)

                    Button("Send Records") {
                        isPresentingSendRecords = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(discoveryStore.documents.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Vault")
            .sheet(isPresented: $isPresentingScanner) {
                NavigationStack {
                    ScannerView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    isPresentingScanner = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $isPresentingAddDocument) {
                AddDocumentSheet { document in
                    discoveryStore.addDocument(document)
                    isPresentingAddDocument = false
                } onCancel: {
                    isPresentingAddDocument = false
                }
            }
            .sheet(isPresented: $isPresentingSendRecords) {
                SendRecordsSheet(
                    petName: discoveryStore.petPass.petName,
                    documents: discoveryStore.documents
                ) {
                    isPresentingSendRecords = false
                }
            }
        }
    }

    private var statusColor: Color {
        switch discoveryStore.petPass.vaccineStatus {
        case .green: return OmniPetColor.emerald
        case .yellow: return OmniPetColor.warning
        case .red: return OmniPetColor.danger
        }
    }
}

// MARK: - Add Document Sheet

struct AddDocumentSheet: View {
    let onAdd: (VaultDocument) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var type: VaultDocument.DocumentType = .medical
    @State private var hasExpiration = false
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    private static let commonDocuments = [
        "Rabies Vaccination",
        "Bordetella Vaccination",
        "DHPP Vaccination",
        "FVRCP Vaccination",
        "Canine Influenza Vaccination",
        "Recent Fecal Test",
        "Microchip Registration",
        "Spay/Neuter Certificate",
    ]

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Title") {
                    TextField("e.g. Rabies Vaccination", text: $title)
                        .textInputAutocapitalization(.words)
                }

                if title.isEmpty {
                    Section("Quick Add") {
                        ForEach(Self.commonDocuments, id: \.self) { name in
                            Button(name) {
                                title = name
                            }
                        }
                    }
                }

                Section("Type") {
                    Picker("Document type", selection: $type) {
                        Text("Medical").tag(VaultDocument.DocumentType.medical)
                        Text("Certificates").tag(VaultDocument.DocumentType.certificates)
                        Text("Identity").tag(VaultDocument.DocumentType.identity)
                        Text("Diet").tag(VaultDocument.DocumentType.diet)
                    }
                    .pickerStyle(.menu)
                }

                Section("Expiration") {
                    Toggle("Has expiration date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section {
                    Button("Add Document") {
                        let doc = VaultDocument(
                            id: UUID(),
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type,
                            expiresOn: hasExpiration ? expirationDate : nil
                        )
                        onAdd(doc)
                    }
                    .disabled(!canAdd)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Send Records Sheet

struct SendRecordsSheet: View {
    let petName: String
    let documents: [VaultDocument]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share \(petName)'s Records")
                            .font(.headline)
                        Text("Select a business from the Discovery tab to send a secure Vault packet with consent controls and expiration.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Documents available to share") {
                    ForEach(documents) { doc in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(doc.title)
                                    .font(.subheadline)
                                Text(doc.expirationText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if doc.isExpired {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(OmniPetColor.danger)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(OmniPetColor.emerald)
                            }
                        }
                    }
                }

                Section {
                    Text("To share records, find a business on the Discover tab and tap \"Check-In with Vault\". You'll choose which documents to include and how long access lasts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Send Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}
