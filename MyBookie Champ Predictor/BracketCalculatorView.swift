import SwiftUI

struct BracketCalculatorView: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID
    @State private var scale: CGFloat = 0.9
    @State private var selectedMatchID: UUID?

    var body: some View {
        Group {
            if let tournament = store.tournaments.first(where: { $0.id == tournamentID }) {
                VStack(spacing: 0) {
                    HStack {
                        ScreenHeader(
                            eyebrow: "\(tournament.name) · \(tournament.plannedMatches.count) Bets Planned",
                            title: "Bracket Calculator",
                            backAction: { dismiss() }
                        )
                        Spacer()
                    }
                    .padding(20)

                    ZStack(alignment: .topTrailing) {
                        ScrollView([.horizontal, .vertical]) {
                            BracketCanvas(tournament: tournament, selectedMatchID: $selectedMatchID)
                                .scaleEffect(scale, anchor: .topLeading)
                                .frame(
                                    width: 720 * scale,
                                    height: max(620, CGFloat(tournament.matches.count) * 92) * scale,
                                    alignment: .topLeading
                                )
                                .padding(20)
                        }

                        VStack(spacing: 8) {
                            ZoomButton(symbol: "plus") { scale = min(1.4, scale + 0.1) }
                            ZoomButton(symbol: "minus") { scale = max(0.65, scale - 0.1) }
                            ZoomButton(symbol: "arrow.counterclockwise") { scale = 0.9 }
                            Text("\(Int(scale * 100))%")
                                .font(.appMono(.caption2))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .padding(12)
                    }

                    BracketSummary(tournament: tournament)
                }
                .sheet(item: selectedMatchBinding(tournament: tournament)) { match in
                    PredictionEditor(tournamentID: tournamentID, matchID: match.id)
                        .environmentObject(store)
                }
            } else {
                ContentUnavailableView("Tournament Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func selectedMatchBinding(tournament: Tournament) -> Binding<TournamentMatch?> {
        Binding(
            get: {
                guard let selectedMatchID else { return nil }
                return tournament.matches.first { $0.id == selectedMatchID }
            },
            set: { selectedMatchID = $0?.id }
        )
    }
}

private struct BracketCanvas: View {
    let tournament: Tournament
    @Binding var selectedMatchID: UUID?

    private var earlyMatches: [TournamentMatch] {
        tournament.matches.filter { [.group, .roundOne, .roundTwo, .quarterfinal].contains($0.stage) }
    }

    private var lateMatches: [TournamentMatch] {
        tournament.matches.filter { [.semifinal, .final].contains($0.stage) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 90) {
            VStack(alignment: .leading, spacing: 16) {
                StagePill(title: tournament.format == .roundRobin ? "League" : "1st Round")
                ForEach(earlyMatches) { match in
                    BracketMatchCard(match: match) {
                        selectedMatchID = match.id
                    }
                }
            }
            VStack(alignment: .leading, spacing: 88) {
                StagePill(title: tournament.format == .roundRobin ? "More Matches" : "Semis & Final")
                ForEach(lateMatches) { match in
                    BracketMatchCard(match: match) {
                        selectedMatchID = match.id
                    }
                }
            }
        }
    }
}

private struct StagePill: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.appMono(.caption))
            .tracking(2)
            .foregroundStyle(AppTheme.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border))
    }
}

private struct BracketMatchCard: View {
    let match: TournamentMatch
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(match.home.name)
                    Spacer()
                    if match.selectedWinnerID == match.home.id {
                        Text("PICK")
                            .foregroundStyle(AppTheme.green)
                    }
                }
                Divider().overlay(AppTheme.border)
                HStack {
                    Text(match.away.name)
                    Spacer()
                    if match.selectedWinnerID == match.away.id {
                        Text("PICK")
                            .foregroundStyle(AppTheme.green)
                    }
                }
                HStack {
                    Text(match.label)
                    Spacer()
                    if match.isPredictionComplete {
                        Text("\(match.americanOdds > 0 ? "+" : "")\(match.americanOdds)")
                            .foregroundStyle(AppTheme.orange)
                        Text(match.stake.currencyText)
                    } else {
                        Label("Add Bet", systemImage: "plus")
                            .foregroundStyle(AppTheme.orange)
                    }
                }
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            }
            .font(.oswald(18, weight: .semibold))
            .foregroundStyle(.white)
            .padding(14)
            .frame(width: 250)
            .background(cardColor, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderColor))
        }
        .buttonStyle(.plain)
    }

    private var cardColor: Color {
        switch match.result {
        case .win: AppTheme.green.opacity(0.10)
        case .loss: AppTheme.red.opacity(0.10)
        case .pending, .push: AppTheme.surface
        }
    }

    private var borderColor: Color {
        switch match.result {
        case .win: AppTheme.green
        case .loss: AppTheme.red
        case .pending, .push: match.isPredictionComplete ? AppTheme.orange : AppTheme.border
        }
    }
}

private struct ZoomButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.border))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus" ? "Zoom in" : symbol == "minus" ? "Zoom out" : "Reset zoom")
    }
}

private struct BracketSummary: View {
    let tournament: Tournament

    var body: some View {
        VStack(spacing: 10) {
            if tournament.invested > tournament.bankroll {
                Label(
                    "Stakes exceed bankroll by \((tournament.invested - tournament.bankroll).currencyText)",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.appMono(.caption))
                .foregroundStyle(AppTheme.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 10) {
                SummaryMetric(title: "Planned", value: tournament.invested.currencyText, color: AppTheme.orange)
                SummaryMetric(title: "Max Profit", value: maxProfit.currencyText, color: AppTheme.green)
                SummaryMetric(title: "Exp. Value", value: expectedValue.currencyText, color: expectedValue >= 0 ? AppTheme.green : AppTheme.red)
            }
        }
        .padding(16)
        .background(AppTheme.background)
        .overlay(alignment: .top) { Divider().overlay(AppTheme.orange.opacity(0.35)) }
    }

    private var maxProfit: Decimal {
        tournament.matches.reduce(0) { $0 + $1.profitIfWin }
    }

    private var expectedValue: Decimal {
        let probability = Decimal(tournament.expectedHitRate)
        return tournament.matches.reduce(0) { result, match in
            result + probability * match.profitIfWin - (1 - probability) * match.stake
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.oswald(24, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.25)))
    }
}

private struct PredictionEditor: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID
    let matchID: UUID
    @State private var winnerID: UUID?
    @State private var odds = "-110"
    @State private var stake = ""
    @State private var notes = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case odds
        case stake
        case notes
    }

    var body: some View {
        NavigationStack {
            if let match = currentMatch {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("BET DRAFT · \(match.label.uppercased())")
                            .font(.appMono(.caption))
                            .tracking(3)
                            .foregroundStyle(AppTheme.orange)
                        Text("\(match.home.name) vs \(match.away.name)")
                            .font(.oswald(34, weight: .bold))

                        Text("SELECT WINNER")
                            .font(.appMono(.caption))
                            .tracking(2)
                            .foregroundStyle(AppTheme.muted)
                        HStack(spacing: 12) {
                            WinnerButton(team: match.home, selection: $winnerID)
                            WinnerButton(team: match.away, selection: $winnerID)
                        }

                        HStack(spacing: 12) {
                            InputCard(title: "American Odds", text: $odds, prefix: nil)
                                .focused($focusedField, equals: .odds)
                            InputCard(title: "Stake Amount", text: $stake, prefix: "$")
                                .focused($focusedField, equals: .stake)
                        }
                        .keyboardType(.numbersAndPunctuation)

                        if let parsedStake, let parsedOdds {
                            HStack(spacing: 12) {
                                SummaryMetric(
                                    title: "Win Amount",
                                    value: profit(stake: parsedStake, odds: parsedOdds).currencyText,
                                    color: AppTheme.green
                                )
                                SummaryMetric(
                                    title: "Total Return",
                                    value: (parsedStake + profit(stake: parsedStake, odds: parsedOdds)).currencyText,
                                    color: .white
                                )
                            }
                        }

                        Text("NOTES (OPTIONAL)")
                            .font(.appMono(.caption))
                            .tracking(2)
                            .foregroundStyle(AppTheme.muted)
                        TextEditor(text: $notes)
                            .focused($focusedField, equals: .notes)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 120)
                            .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))

                        if !isValid {
                            Label("Choose a winner and enter valid non-zero odds and stake.", systemImage: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(AppTheme.red)
                        }

                        PrimaryButton(title: "Save Prediction", isDisabled: !isValid) {
                            save()
                        }
                    }
                    .padding(20)
                }
                .background(AppTheme.background)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
                .onAppear {
                    winnerID = match.selectedWinnerID
                    odds = String(match.americanOdds)
                    stake = match.stake == 0 ? "" : NSDecimalNumber(decimal: match.stake).stringValue
                    notes = match.notes
                }
            }
        }
    }

    private var currentMatch: TournamentMatch? {
        store.tournaments
            .first(where: { $0.id == tournamentID })?
            .matches.first(where: { $0.id == matchID })
    }

    private var parsedOdds: Int? {
        guard let value = Int(odds), value != 0 else { return nil }
        return value
    }

    private var parsedStake: Decimal? {
        guard let value = Decimal(string: stake), value > 0 else { return nil }
        return value
    }

    private var isValid: Bool {
        winnerID != nil && parsedOdds != nil && parsedStake != nil
    }

    private func profit(stake: Decimal, odds: Int) -> Decimal {
        odds > 0 ? stake * Decimal(odds) / 100 : stake * 100 / Decimal(abs(odds))
    }

    private func save() {
        guard var tournament = store.tournaments.first(where: { $0.id == tournamentID }),
              let index = tournament.matches.firstIndex(where: { $0.id == matchID }),
              let parsedOdds,
              let parsedStake else { return }
        tournament.matches[index].selectedWinnerID = winnerID
        tournament.matches[index].americanOdds = parsedOdds
        tournament.matches[index].stake = parsedStake
        tournament.matches[index].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        store.update(tournament)
        dismiss()
    }
}

struct WinnerButton: View {
    let team: Team
    @Binding var selection: UUID?

    var body: some View {
        Button {
            selection = team.id
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "sportscourt.fill")
                    .font(.title)
                Text(team.name)
                    .font(.oswald(20, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 125)
            .padding(12)
            .background(
                selection == team.id ? AppTheme.orange.opacity(0.16) : AppTheme.raisedSurface,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selection == team.id ? AppTheme.orange : AppTheme.border)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == team.id ? .isSelected : [])
    }
}

private struct InputCard: View {
    let title: String
    @Binding var text: String
    let prefix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            HStack {
                if let prefix {
                    Text(prefix).foregroundStyle(AppTheme.orange)
                }
                TextField("0", text: $text)
                    .font(.appMono(.title2))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))
    }
}
