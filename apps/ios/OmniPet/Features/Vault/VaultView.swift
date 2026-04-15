import SwiftUI
import VisionKit

struct VaultView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var isPresentingScanner = false
    @State private var isPresentingAddDocument = false
    @State private var isPresentingSendRecords = false
    @State private var isPresentingEditPetPass = false
    @State private var editingDocument: VaultDocument?
    @State private var scannedImages: [UIImage] = []

    private var scannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isPresentingEditPetPass = true
                    } label: {
                        petPassCard
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                if discoveryStore.documents.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Text("No documents yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Add your pet's vaccine records, certificates, and other documents to get started.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 8)
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
                } else {
                    ForEach(documentGroups, id: \.type) { group in
                        Section {
                            ForEach(group.documents) { document in
                                Button {
                                    editingDocument = document
                                } label: {
                                    documentRow(document)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteDocuments(in: group, at: offsets)
                            }
                        } header: {
                            if group.type == documentGroups.first?.type {
                                HStack {
                                    Text(group.type.rawValue)
                                    Spacer()
                                    Button {
                                        isPresentingAddDocument = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(OmniPetColor.emerald)
                                    }
                                }
                            } else {
                                Text(group.type.rawValue)
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button {
                        if scannerAvailable {
                            isPresentingScanner = true
                        } else {
                            // Fall back to manual add on simulator / unsupported devices
                            isPresentingAddDocument = true
                        }
                    } label: {
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
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
            .fullScreenCover(isPresented: $isPresentingScanner) {
                DocumentCameraView { images in
                    scannedImages = images
                    isPresentingScanner = false
                    isPresentingAddDocument = true
                } onCancelled: {
                    isPresentingScanner = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isPresentingAddDocument) {
                AddDocumentSheet(scannedPageCount: scannedImages.count) { document in
                    discoveryStore.addDocument(document)
                    scannedImages = []
                    isPresentingAddDocument = false
                } onCancel: {
                    scannedImages = []
                    isPresentingAddDocument = false
                }
            }
            .sheet(item: $editingDocument) { document in
                EditDocumentSheet(document: document) { updated in
                    discoveryStore.updateDocument(updated)
                    editingDocument = nil
                } onCancel: {
                    editingDocument = nil
                }
            }
            .sheet(isPresented: $isPresentingEditPetPass) {
                EditPetPassSheet(petPass: discoveryStore.petPass) { updated in
                    discoveryStore.updatePetPass(updated)
                    isPresentingEditPetPass = false
                } onCancel: {
                    isPresentingEditPetPass = false
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

    private struct DocumentGroup {
        let type: VaultDocument.DocumentType
        let documents: [VaultDocument]
    }

    private var documentGroups: [DocumentGroup] {
        let grouped = Dictionary(grouping: discoveryStore.documents, by: \.type)
        return VaultDocument.DocumentType.allCases.compactMap { type in
            guard let docs = grouped[type], !docs.isEmpty else { return nil }
            return DocumentGroup(type: type, documents: docs)
        }
    }

    private func deleteDocuments(in group: DocumentGroup, at offsets: IndexSet) {
        let idsToDelete = offsets.map { group.documents[$0].id }
        for id in idsToDelete {
            if let idx = discoveryStore.documents.firstIndex(where: { $0.id == id }) {
                discoveryStore.deleteDocument(at: IndexSet(integer: idx))
            }
        }
    }

    private func documentRow(_ document: VaultDocument) -> some View {
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
                } else if document.isExpiringSoon {
                    Text("Expiring Soon")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(OmniPetColor.warning.opacity(0.15), in: Capsule())
                        .foregroundStyle(OmniPetColor.warning)
                }
            }
            Text(document.expirationText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var petPassCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(discoveryStore.petPass.petName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(discoveryStore.petPass.breed) · \(discoveryStore.petPass.ageDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(discoveryStore.petPass.species.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.2), in: Capsule())
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: discoveryStore.petPass.species == .dog ? "dog.fill" : "cat.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(16)

            HStack {
                Label(discoveryStore.vaccineStatus.label, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                Spacer()
                Text("PET PASS")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.15))
        }
        .background(
            LinearGradient(
                colors: [OmniPetColor.emerald, OmniPetColor.emerald.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusIcon: String {
        switch discoveryStore.vaccineStatus {
        case .green: return "checkmark.shield.fill"
        case .yellow: return "exclamationmark.shield.fill"
        case .red: return "xmark.shield.fill"
        }
    }

    private var statusColor: Color {
        switch discoveryStore.vaccineStatus {
        case .green: return .white
        case .yellow: return OmniPetColor.warning
        case .red: return OmniPetColor.danger
        }
    }
}

// MARK: - Add Document Sheet

struct AddDocumentSheet: View {
    let scannedPageCount: Int
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
                if scannedPageCount > 0 {
                    Section {
                        Label("\(scannedPageCount) page\(scannedPageCount == 1 ? "" : "s") scanned", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(OmniPetColor.emerald)
                        Text("Name this document and set its type and expiration below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
                        ForEach(VaultDocument.DocumentType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
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
            .navigationTitle(scannedPageCount > 0 ? "Tag Scanned Document" : "Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Edit Document Sheet

struct EditDocumentSheet: View {
    let document: VaultDocument
    let onSave: (VaultDocument) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var type: VaultDocument.DocumentType
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date

    init(document: VaultDocument, onSave: @escaping (VaultDocument) -> Void, onCancel: @escaping () -> Void) {
        self.document = document
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: document.title)
        _type = State(initialValue: document.type)
        _hasExpiration = State(initialValue: document.expiresOn != nil)
        _expirationDate = State(initialValue: document.expiresOn ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Title") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                }

                Section("Type") {
                    Picker("Document type", selection: $type) {
                        ForEach(VaultDocument.DocumentType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
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
                    Button("Save Changes") {
                        let updated = VaultDocument(
                            id: document.id,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type,
                            expiresOn: hasExpiration ? expirationDate : nil
                        )
                        onSave(updated)
                    }
                    .disabled(!canSave)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Edit Pet Pass Sheet

struct EditPetPassSheet: View {
    let petPass: PetPass
    let onSave: (PetPass) -> Void
    let onCancel: () -> Void

    @State private var petName: String
    @State private var breed: String
    @State private var ageDescription: String
    @State private var species: Species

    init(petPass: PetPass, onSave: @escaping (PetPass) -> Void, onCancel: @escaping () -> Void) {
        self.petPass = petPass
        self.onSave = onSave
        self.onCancel = onCancel
        _petName = State(initialValue: petPass.petName)
        _breed = State(initialValue: petPass.breed)
        _ageDescription = State(initialValue: petPass.ageDescription)
        _species = State(initialValue: petPass.species)
    }

    private var canSave: Bool {
        !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet Details") {
                    TextField("Name", text: $petName)
                        .textInputAutocapitalization(.words)
                    TextField("Breed", text: $breed)
                        .textInputAutocapitalization(.words)
                    TextField("Age (e.g. 3 years)", text: $ageDescription)
                }

                Section("Species") {
                    Picker("Species", selection: $species) {
                        ForEach(Species.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Save") {
                        let updated = PetPass(
                            id: petPass.id,
                            petName: petName.trimmingCharacters(in: .whitespacesAndNewlines),
                            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                            ageDescription: ageDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                            species: species
                        )
                        onSave(updated)
                    }
                    .disabled(!canSave)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Pet Pass")
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
