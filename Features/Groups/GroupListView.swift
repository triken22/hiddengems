import SwiftUI

struct GroupListView: View {
    @ObservedObject var viewModel: GroupListViewModel
    @State private var newGroupName: String = ""
    @State private var presentedError: ErrorMessage?

    var body: some View {
        NavigationStack {
            List {
                Section("Your Groups") {
                    ForEach(viewModel.groups) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.headline)
                            Text("Members: \(group.memberCount)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Create Group") {
                    HStack {
                        TextField("Group name", text: $newGroupName)
                        Button("Create") {
                            let name = newGroupName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            Task { await viewModel.createGroup(named: name) }
                            newGroupName = ""
                        }
                    }
                }

                Section("Join Group") {
                    TextField("Invite code", text: $viewModel.inviteCodeToJoin)
                        .textInputAutocapitalization(.characters)
                    Button("Join") {
                        Task { await viewModel.joinGroup() }
                    }
                }
            }
            .navigationTitle("Groups")
            .alert(item: $presentedError) { message in
                Alert(title: Text("Error"), message: Text(message.message))
            }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error = error {
                presentedError = ErrorMessage(message: error)
            }
        }
    }
}

private struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}
