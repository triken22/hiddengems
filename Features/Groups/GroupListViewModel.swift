import Foundation
import Combine

@MainActor
final class GroupListViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isCreatingGroup = false
    @Published var inviteCodeToJoin: String = ""
    @Published var errorMessage: String?

    let groupRepository: GroupRepository
    let syncCoordinator: SyncCoordinator

    private var cancellables: Set<AnyCancellable> = []

    init(groupRepository: GroupRepository, syncCoordinator: SyncCoordinator) {
        self.groupRepository = groupRepository
        self.syncCoordinator = syncCoordinator
        observeGroups()
    }

    private func observeGroups() {
        groupRepository.groupsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                self?.groups = groups
            }
            .store(in: &cancellables)
    }

    func createGroup(named name: String) async {
        do {
            try await groupRepository.createGroup(name: name)
            errorMessage = nil
            await syncCoordinator.pushChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinGroup() async {
        guard !inviteCodeToJoin.isEmpty else { return }
        do {
            try await groupRepository.joinGroup(inviteCode: inviteCodeToJoin)
            inviteCodeToJoin = ""
            errorMessage = nil
            await syncCoordinator.pullChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
