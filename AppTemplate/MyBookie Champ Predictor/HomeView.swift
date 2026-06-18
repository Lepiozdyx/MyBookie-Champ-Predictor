import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TournamentStore
    @State private var showsWizard = false
    @State private var tournamentToDelete: Tournament?
    @State private var openedTournament: Tournament?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenHeader(eyebrow: "Champ Predictor · Live", title: "My Tournaments")

                        switch store.loadState {
                        case .loading:
                            loadingState
                        case .failed(let message):
                            errorState(message)
                        case .ready:
                            if store.tournaments.isEmpty {
                                emptyState
                            } else {
                                portfolioCard
                                tournamentSections
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }

                if !store.tournaments.isEmpty {
                    PrimaryButton(title: "New Tournament", symbol: "plus") {
                        showsWizard = true
                    }
                    .frame(width: 260)
                    .padding(.trailing, 20)
                    .padding(.bottom, 22)
                }
            }
            .background(AppTheme.background)
            .sheet(isPresented: $showsWizard) {
                TournamentWizard()
                    .environmentObject(store)
            }
            .navigationDestination(item: $openedTournament) { tournament in
                TournamentDetailView(tournamentID: tournament.id)
            }
            .confirmationDialog(
                "Delete tournament?",
                isPresented: Binding(
                    get: { tournamentToDelete != nil },
                    set: { if !$0 { tournamentToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let tournamentToDelete {
                        store.delete(tournamentToDelete)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the bracket, predictions, results, and analytics from this device.")
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppTheme.orange)
            Text("Opening your tournaments…")
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Open Tournaments", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { store.retryLoad() }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.orange)
        }
        .frame(minHeight: 420)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 100)
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.orange)
            Text("Nothing here yet")
                .font(.oswald(30, weight: .bold))
            Text("Build a tournament plan, assign a bankroll, and map your predictions before play begins.")
                .font(.body)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
            PrimaryButton(title: "New Tournament", symbol: "plus") {
                showsWizard = true
            }
            .padding(.top, 8)
            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity, minHeight: 590)
    }

    private var portfolioCard: some View {
        let active = store.tournaments.filter { !$0.isCompleted }
        let bankroll = store.tournaments.reduce(Decimal.zero) { $0 + $1.bankroll }
        let invested = store.tournaments.reduce(Decimal.zero) { $0 + $1.invested }
        let profit = store.tournaments.reduce(Decimal.zero) { $0 + $1.settledProfit }
        let roi = invested > 0
            ? NSDecimalNumber(decimal: profit / invested).doubleValue * 100
            : 0

        return AppCard(accent: AppTheme.orange) {
            VStack(alignment: .leading, spacing: 18) {
                Text("PORTFOLIO OVERVIEW · \(active.count) ACTIVE")
                    .font(.appMono(.caption))
                    .tracking(2)
                    .foregroundStyle(AppTheme.muted)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TOTAL BALANCE")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                        Text((bankroll + profit).currencyText)
                            .font(.oswald(50, weight: .bold))
                            .minimumScaleFactor(0.7)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("PORTFOLIO ROI")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                        Text(roi.percentageText)
                            .font(.oswald(38, weight: .bold))
                            .foregroundStyle(roi >= 0 ? AppTheme.green : AppTheme.red)
                    }
                }
                Divider().overlay(AppTheme.border)
                HStack {
                    PortfolioMetric(title: "Bankroll", value: bankroll.currencyText)
                    PortfolioMetric(title: "Invested", value: invested.currencyText)
                    PortfolioMetric(
                        title: "P&L",
                        value: profit.currencyText,
                        color: profit >= 0 ? AppTheme.green : AppTheme.red
                    )
                }
            }
        }
    }

    private var tournamentSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            TournamentSectionLabel(title: "Active Tournaments", count: store.tournaments.filter { !$0.isCompleted }.count)
            ForEach(store.tournaments.filter { !$0.isCompleted }) { tournament in
                TournamentCard(tournament: tournament) {
                    store.selectedTournamentID = tournament.id
                    openedTournament = tournament
                } onDelete: {
                    tournamentToDelete = tournament
                }
            }

            let completed = store.tournaments.filter(\.isCompleted)
            if !completed.isEmpty {
                TournamentSectionLabel(title: "Completed", count: completed.count)
                    .padding(.top, 8)
                ForEach(completed) { tournament in
                    TournamentCard(tournament: tournament) {
                        store.selectedTournamentID = tournament.id
                        openedTournament = tournament
                    } onDelete: {
                        tournamentToDelete = tournament
                    }
                }
            }
        }
    }
}

private struct PortfolioMetric: View {
    let title: String
    let value: String
    var color: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.appMono(.headline))
                .foregroundStyle(color)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TournamentSectionLabel: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appMono(.caption))
                .tracking(2)
                .foregroundStyle(AppTheme.muted)
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)
            Text("\(count)")
                .font(.appMono(.caption))
                .foregroundStyle(AppTheme.muted)
        }
    }
}

private struct TournamentCard: View {
    let tournament: Tournament
    let action: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: action) {
            AppCard(accent: tournament.roi >= 0 ? AppTheme.green : AppTheme.red) {
                VStack(spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        EmojiBadge(
                            emoji: tournament.sport.emoji,
                            size: 62,
                            tint: tournament.roi >= 0 ? AppTheme.green : AppTheme.orange
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tournament.sport.category.uppercased())
                                .font(.appMono(.caption2))
                                .tracking(2)
                                .foregroundStyle(AppTheme.muted)
                            Text(tournament.name)
                                .font(.oswald(25, weight: .bold))
                                .lineLimit(2)
                            Label(
                                tournament.isCompleted ? "Completed" : currentStage,
                                systemImage: tournament.isCompleted ? "checkmark.circle.fill" : "circle.fill"
                            )
                            .font(.appMono(.caption))
                            .foregroundStyle(tournament.isCompleted ? AppTheme.muted : AppTheme.green)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(tournament.roi.percentageText)
                                .font(.oswald(29, weight: .bold))
                                .foregroundStyle(tournament.roi >= 0 ? AppTheme.green : AppTheme.red)
                            Text("ROI")
                                .font(.appMono(.caption2))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }

                    HStack(spacing: 10) {
                        TournamentMetric(title: "Bankroll", value: tournament.bankroll.currencyText)
                        TournamentMetric(title: "Invested", value: tournament.invested.currencyText)
                        TournamentMetric(title: "Balance", value: tournament.balance.currencyText)
                    }

                    HStack {
                        ProgressView(value: progress)
                            .tint(AppTheme.orange)
                        Text("\(Int(progress * 100))%")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AppTheme.muted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Tournament", systemImage: "trash")
            }
        }
        .accessibilityHint("Opens bracket and tournament tools")
    }

    private var progress: Double {
        guard !tournament.matches.isEmpty else { return 0 }
        let settled = tournament.matches.filter { $0.result != .pending }.count
        return Double(settled) / Double(tournament.matches.count)
    }

    private var currentStage: String {
        tournament.matches.first(where: { $0.result == .pending })?.stage.rawValue ?? "Final"
    }
}

private struct TournamentMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.appMono(.subheadline))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}
