import SwiftUI

struct GroupStageView: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID
    @State private var expandedGroupIDs: Set<UUID> = []
    @State private var showsNewGroup = false
    @State private var editingGroup: TeamGroup?
    @State private var groupToDelete: TeamGroup?

    var body: some View {
        Group {
            if let tournament = store.tournaments.first(where: { $0.id == tournamentID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(
                            eyebrow: "\(tournament.name) · Group Stage",
                            title: "Group Stage",
                            backAction: { dismiss() }
                        )

                        if tournament.groups.isEmpty {
                            ContentUnavailableView {
                                Label("No Groups Yet", systemImage: "person.3")
                            } description: {
                                Text("Create a visual group and add teams to organize the field.")
                            }
                            .frame(minHeight: 430)
                        } else {
                            ForEach(tournament.groups) { group in
                                GroupCard(
                                    group: group,
                                    isExpanded: expandedGroupIDs.contains(group.id),
                                    onToggle: { toggle(group.id) },
                                    onEdit: { editingGroup = group },
                                    onDelete: { groupToDelete = group }
                                )
                            }
                        }

                        PrimaryButton(title: "New Group", symbol: "plus") {
                            showsNewGroup = true
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
                .sheet(isPresented: $showsNewGroup) {
                    GroupEditor(tournamentID: tournamentID)
                        .environmentObject(store)
                }
                .sheet(item: $editingGroup) { group in
                    GroupEditor(tournamentID: tournamentID, group: group)
                        .environmentObject(store)
                }
                .confirmationDialog(
                    "Delete \(groupToDelete?.name ?? "group")?",
                    isPresented: Binding(
                        get: { groupToDelete != nil },
                        set: { if !$0 { groupToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        deleteGroup()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes only the visual group. Existing bracket matches stay unchanged.")
                }
            }
        }
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggle(_ id: UUID) {
        if expandedGroupIDs.contains(id) {
            expandedGroupIDs.remove(id)
        } else {
            expandedGroupIDs.insert(id)
        }
    }

    private func deleteGroup() {
        guard var tournament = store.tournaments.first(where: { $0.id == tournamentID }),
              let groupToDelete else { return }
        tournament.groups.removeAll { $0.id == groupToDelete.id }
        store.update(tournament)
        self.groupToDelete = nil
    }
}

private struct GroupCard: View {
    let group: TeamGroup
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        AppCard(accent: isExpanded ? AppTheme.orange : nil) {
            VStack(spacing: 14) {
                HStack {
                    Button(action: onToggle) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.oswald(27, weight: .bold))
                            Text("\(group.teams.count) teams")
                                .font(.appMono(.caption))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit \(group.name)")
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(isExpanded ? AppTheme.orange : AppTheme.muted)
                    }
                    .accessibilityLabel(isExpanded ? "Collapse group" : "Expand group")
                }

                if isExpanded {
                    Divider().overlay(AppTheme.border)
                    ForEach(Array(group.teams.enumerated()), id: \.element.id) { index, team in
                        HStack {
                            Text(String(format: "%02d", index + 1))
                                .font(.appMono(.caption))
                                .foregroundStyle(AppTheme.muted)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 10))
                            Text(team.name)
                                .font(.oswald(21, weight: .semibold))
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 15))
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Group", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.red)
                }
            }
        }
    }
}

private struct GroupEditor: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID
    var group: TeamGroup?
    @State private var name = ""
    @State private var teamNames: [String] = [""]
    @FocusState private var focusedIndex: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Group") {
                    TextField("Group name", text: $name)
                }
                Section("Teams") {
                    ForEach(teamNames.indices, id: \.self) { index in
                        HStack {
                            TextField("Team \(index + 1)", text: $teamNames[index])
                                .focused($focusedIndex, equals: index)
                            if teamNames.count > 1 {
                                Button(role: .destructive) {
                                    teamNames.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                            }
                        }
                    }
                    Button("Add Team", systemImage: "plus") {
                        teamNames.append("")
                        focusedIndex = teamNames.count - 1
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(group == nil ? "New Group" : "Edit Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(cleanName.isEmpty || cleanTeams.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedIndex = nil }
                }
            }
            .onAppear {
                name = group?.name ?? ""
                teamNames = group?.teams.map(\.name) ?? [""]
            }
        }
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanTeams: [String] {
        teamNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func save() {
        guard var tournament = store.tournaments.first(where: { $0.id == tournamentID }) else { return }
        let teams = cleanTeams.map { Team(name: $0, shortName: String($0.prefix(3)).uppercased()) }
        if let group, let index = tournament.groups.firstIndex(where: { $0.id == group.id }) {
            tournament.groups[index].name = cleanName
            tournament.groups[index].teams = teams
        } else {
            tournament.groups.append(TeamGroup(name: cleanName, teams: teams))
        }
        store.update(tournament)
        dismiss()
    }
}
