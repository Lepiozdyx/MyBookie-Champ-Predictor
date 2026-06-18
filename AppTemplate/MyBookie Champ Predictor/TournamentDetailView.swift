import SwiftUI

struct TournamentDetailView: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID

    var body: some View {
        Group {
            if let tournament = store.tournaments.first(where: { $0.id == tournamentID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenHeader(
                            eyebrow: "\(tournament.name) · \(tournament.plannedMatches.count) Bets Planned",
                            title: "Tournament",
                            backAction: { dismiss() }
                        )

                        AppCard(accent: AppTheme.orange) {
                            HStack(spacing: 16) {
                                EmojiBadge(
                                    emoji: tournament.sport.emoji,
                                    size: 72,
                                    tint: AppTheme.orange
                                )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tournament.name)
                                        .font(.oswald(28, weight: .bold))
                                    Text(tournament.format.title)
                                        .font(.appMono(.caption))
                                        .foregroundStyle(AppTheme.muted)
                                    Text("\(tournament.bankroll.currencyText) bankroll · \(Int(tournament.expectedHitRate * 100))% expected hit rate")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        NavigationLink {
                            BracketCalculatorView(tournamentID: tournamentID)
                        } label: {
                            FeatureLinkCard(
                                symbol: "point.3.connected.trianglepath.dotted",
                                title: "Bracket Calculator",
                                detail: "Plan winners, American odds, stakes, and notes."
                            )
                        }
                        .buttonStyle(.plain)

                        if tournament.format == .groupPlayoffs {
                            NavigationLink {
                                GroupStageView(tournamentID: tournamentID)
                            } label: {
                                FeatureLinkCard(
                                    symbol: "person.3.fill",
                                    title: "Group Stage",
                                    detail: "Visually organize teams before the bracket."
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            TournamentLiveView(tournamentID: tournamentID)
                        } label: {
                            FeatureLinkCard(
                                symbol: "bolt.fill",
                                title: "Live Updates",
                                detail: "Record actual winners and grade every prediction."
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TournamentAnalyticsView(tournamentID: tournamentID)
                        } label: {
                            FeatureLinkCard(
                                symbol: "chart.bar.xaxis",
                                title: "Analytics",
                                detail: "Review ROI, P&L, win rate, and stage performance."
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            } else {
                ContentUnavailableView("Tournament Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct FeatureLinkCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        AppCard {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.oswald(25, weight: .bold))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
        }
    }
}
