import SwiftUI

struct LiveView: View {
    @EnvironmentObject private var store: TournamentStore

    var body: some View {
        NavigationStack {
            if let tournament = store.selectedTournament {
                TournamentLiveContent(tournamentID: tournament.id, showsBackButton: false)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ScreenHeader(eyebrow: "Unavailable", title: "Live Updates")
                        LiveStats(matches: [])
                        ContentUnavailableView {
                            Label("Nothing Here Yet", systemImage: "bolt.slash")
                        } description: {
                            Text("Create a tournament and add predictions before recording live results.")
                        }
                        .frame(minHeight: 460)
                    }
                    .padding(20)
                }
                .background(AppTheme.background)
            }
        }
    }
}

struct TournamentLiveView: View {
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID

    var body: some View {
        TournamentLiveContent(
            tournamentID: tournamentID,
            showsBackButton: true,
            backAction: { dismiss() }
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TournamentLiveContent: View {
    @EnvironmentObject private var store: TournamentStore
    let tournamentID: UUID
    var showsBackButton = false
    var backAction: (() -> Void)?
    @State private var gradingMatch: TournamentMatch?
    @State private var initialResult: PredictionResult = .pending

    var body: some View {
        Group {
            if let tournament = store.tournaments.first(where: { $0.id == tournamentID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top) {
                            ScreenHeader(
                                eyebrow: tournament.name,
                                title: "Live Updates",
                                backAction: showsBackButton ? backAction : nil
                            )
                            Spacer()
                            if !showsBackButton && store.tournaments.count > 1 {
                                TournamentPicker(selectedID: tournamentID)
                            }
                        }

                        LiveStats(matches: tournament.plannedMatches)

                        if !tournament.affectedMatches.isEmpty {
                            DominoSummary(tournament: tournament)
                        }

                        let planned = tournament.plannedMatches
                        if planned.isEmpty {
                            ContentUnavailableView {
                                Label("No Predictions Yet", systemImage: "bolt.slash")
                            } description: {
                                Text("Open Bracket Calculator and add a winner, odds, and stake.")
                            }
                            .frame(minHeight: 420)
                        } else {
                            SectionLabel(title: "Grade Matches")
                            ForEach(planned) { match in
                                LiveMatchCard(match: match) { result in
                                    initialResult = result
                                    gradingMatch = match
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
                .sheet(item: $gradingMatch) { match in
                    MatchResultEditor(
                        tournamentID: tournamentID,
                        matchID: match.id,
                        initialResult: initialResult
                    )
                    .environmentObject(store)
                }
            }
        }
        .background(AppTheme.background)
    }
}

private struct TournamentPicker: View {
    @EnvironmentObject private var store: TournamentStore
    let selectedID: UUID

    var body: some View {
        Menu {
            ForEach(store.tournaments) { tournament in
                Button {
                    store.selectedTournamentID = tournament.id
                } label: {
                    if tournament.id == selectedID {
                        Label(tournament.name, systemImage: "checkmark")
                    } else {
                        Text(tournament.name)
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .frame(width: 44, height: 44)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Select tournament")
    }
}

struct LiveStats: View {
    let matches: [TournamentMatch]

    var body: some View {
        HStack(spacing: 9) {
            LiveStat(title: "Won", value: "\(matches.filter { $0.result == .win }.count)", color: AppTheme.green)
            LiveStat(title: "Lost", value: "\(matches.filter { $0.result == .loss }.count)", color: AppTheme.red)
            LiveStat(title: "Pending", value: "\(matches.filter { $0.result == .pending }.count)", color: AppTheme.orange)
            LiveStat(
                title: "P&L",
                value: matches.reduce(Decimal.zero) { $0 + $1.settledProfit }.currencyText,
                color: matches.reduce(Decimal.zero) { $0 + $1.settledProfit } >= 0 ? AppTheme.green : AppTheme.red
            )
        }
    }
}

private struct LiveStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.oswald(24, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))
    }
}

private struct DominoSummary: View {
    let tournament: Tournament

    var body: some View {
        VStack(spacing: 14) {
            AppCard(accent: AppTheme.red) {
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(AppTheme.red)
                        .frame(width: 54, height: 54)
                        .background(AppTheme.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DOMINO EFFECT")
                            .font(.oswald(24, weight: .bold))
                        Text("\(tournament.affectedMatches.count) future predictions include an eliminated team. Open the bracket to revise them.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }

            ForEach(tournament.affectedMatches) { match in
                HStack {
                    VStack(alignment: .leading) {
                        Text(match.label)
                            .font(.oswald(19, weight: .bold))
                        Text("\(match.home.shortName) vs \(match.away.shortName)")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    Label(match.stake.currencyText, systemImage: "exclamationmark.triangle")
                        .font(.appMono(.caption))
                        .foregroundStyle(AppTheme.red)
                }
                .padding(16)
                .background(AppTheme.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.red.opacity(0.5)))
            }
        }
    }
}

private struct SectionLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appMono(.caption))
                .tracking(2)
                .foregroundStyle(AppTheme.muted)
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }
}

private struct LiveMatchCard: View {
    let match: TournamentMatch
    let onGrade: (PredictionResult) -> Void

    var body: some View {
        AppCard(accent: resultColor) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(match.label.uppercased())
                            .font(.appMono(.caption2))
                            .foregroundStyle(AppTheme.muted)
                        Text(match.home.name)
                            .font(.oswald(23, weight: .bold))
                            .foregroundStyle(match.selectedWinnerID == match.home.id ? AppTheme.orange : .white)
                        Text("vs")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                        Text(match.away.name)
                            .font(.oswald(23, weight: .bold))
                            .foregroundStyle(match.selectedWinnerID == match.away.id ? AppTheme.orange : .white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Pick: \(match.selectedWinner?.name ?? "—")")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.orange)
                        Text("Stake: \(match.stake.currencyText)")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                        if match.result != .pending {
                            Text(match.result.rawValue.uppercased())
                                .font(.oswald(22, weight: .bold))
                                .foregroundStyle(resultColor ?? .white)
                            Text(match.settledProfit.currencyText)
                                .font(.appMono(.caption))
                                .foregroundStyle(resultColor ?? .white)
                        }
                    }
                }

                if match.result == .pending {
                    HStack(spacing: 10) {
                        GradeButton(title: "Win", color: AppTheme.green) { onGrade(.win) }
                        GradeButton(title: "Loss", color: AppTheme.red) { onGrade(.loss) }
                        GradeButton(title: "Push", color: AppTheme.muted) { onGrade(.push) }
                    }
                } else {
                    Button {
                        onGrade(match.result)
                    } label: {
                        Label("Edit Result", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.orange)
                }
            }
        }
    }

    private var resultColor: Color? {
        switch match.result {
        case .win: AppTheme.green
        case .loss: AppTheme.red
        case .push: AppTheme.muted
        case .pending: nil
        }
    }
}

private struct GradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.appMono(.caption))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }
}

private struct MatchResultEditor: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID
    let matchID: UUID
    let initialResult: PredictionResult
    @State private var result: PredictionResult = .pending
    @State private var actualWinnerID: UUID?

    var body: some View {
        NavigationStack {
            if let match = currentMatch {
                VStack(alignment: .leading, spacing: 24) {
                    Text(match.label.uppercased())
                        .font(.appMono(.caption))
                        .tracking(3)
                        .foregroundStyle(AppTheme.orange)
                    Text("Record Actual Outcome")
                        .font(.oswald(36, weight: .bold))
                    Text("The actual winner drives the bracket’s domino effect. The prediction result drives P&L.")
                        .foregroundStyle(AppTheme.muted)

                    Text("ACTUAL WINNER")
                        .font(.appMono(.caption))
                        .foregroundStyle(AppTheme.muted)
                    HStack(spacing: 12) {
                        WinnerButton(team: match.home, selection: $actualWinnerID)
                        WinnerButton(team: match.away, selection: $actualWinnerID)
                    }

                    Text("PREDICTION RESULT")
                        .font(.appMono(.caption))
                        .foregroundStyle(AppTheme.muted)
                    HStack(spacing: 10) {
                        ResultSelection(title: "Win", value: .win, selection: $result, color: AppTheme.green)
                        ResultSelection(title: "Loss", value: .loss, selection: $result, color: AppTheme.red)
                        ResultSelection(title: "Push", value: .push, selection: $result, color: AppTheme.muted)
                    }

                    Spacer()
                    PrimaryButton(title: "Save Result", isDisabled: actualWinnerID == nil || result == .pending) {
                        save()
                    }
                }
                .padding(20)
                .background(AppTheme.background)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .onAppear {
                    actualWinnerID = match.actualWinnerID
                    result = match.result == .pending ? initialResult : match.result
                }
            }
        }
    }

    private var currentMatch: TournamentMatch? {
        store.tournaments.first(where: { $0.id == tournamentID })?
            .matches.first(where: { $0.id == matchID })
    }

    private func save() {
        guard var tournament = store.tournaments.first(where: { $0.id == tournamentID }),
              let index = tournament.matches.firstIndex(where: { $0.id == matchID }) else { return }
        tournament.matches[index].actualWinnerID = actualWinnerID
        tournament.matches[index].result = result
        store.update(tournament)
        dismiss()
    }
}

private struct ResultSelection: View {
    let title: String
    let value: PredictionResult
    @Binding var selection: PredictionResult
    let color: Color

    var body: some View {
        Button {
            selection = value
        } label: {
            Text(title.uppercased())
                .font(.appMono(.caption))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(color)
                .background(color.opacity(selection == value ? 0.20 : 0.07), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selection == value ? color : AppTheme.border)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}
