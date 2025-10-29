import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuickAddViewModel
    @State private var presentedError: ErrorMessage?

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    init(viewModel: QuickAddViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Notes", text: $viewModel.details, axis: .vertical)
                }

                Section("Photos") {
                    Label("Photo picker temporarily disabled", systemImage: "photo.on.rectangle")
                        .foregroundColor(.secondary)
                }

                Section("Suggested Tags") {
                    if viewModel.suggestedTags.isEmpty {
                        Text("No suggestions yet")
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(viewModel.suggestedTags, id: \.self) { tag in
                                Text(tag)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                let success = await viewModel.save()
                                if success { dismiss() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quick Add")
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            presentedError = newValue.map { ErrorMessage(message: $0) }
        }
        .alert(item: $presentedError) { message in
            Alert(title: Text("Error"), message: Text(message.message))
        }
    }
}

private struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}
