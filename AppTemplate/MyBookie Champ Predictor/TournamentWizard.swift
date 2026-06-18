import SwiftUI

struct TournamentWizard: View {
    @EnvironmentObject private var store: TournamentStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var sport: SportTemplate = .worldCup
    @State private var format: BracketFormat = .groupPlayoffs
    @State private var bankroll: Double = 500
    @State private var hitRate: Double = 60

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ScreenHeader(
                        eyebrow: "Setup Wizard · Step \(step + 1)/3",
                        title: "New Tournament",
                        backAction: goBack
                    )
                    WizardProgress(step: step)

                    Group {
                        switch step {
                        case 0:
                            sportStep
                        case 1:
                            formatStep
                        default:
                            bankrollStep
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: step)
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    if step > 0 {
                        Button {
                            step -= 1
                        } label: {
                            Label("Back", systemImage: "arrow.left")
                                .font(.oswald(21, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                    PrimaryButton(
                        title: step == 2 ? "Generate Bracket" : "Continue",
                        symbol: step == 2 ? "trophy" : "arrow.right"
                    ) {
                        if step == 2 {
                            createTournament()
                        } else {
                            step += 1
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.94))
            }
            .background(AppTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }

    private var sportStep: some View {
        VStack(spacing: 14) {
            ForEach(SportTemplate.allCases) { item in
                SelectionCard(
                    title: item.title,
                    detail: item.detail,
                    emoji: item.emoji,
                    isSelected: item == sport
                ) {
                    sport = item
                    if item == .nba || item == .nhl || item == .grandSlam {
                        format = .playoffs
                    }
                }
            }
        }
    }

    private var formatStep: some View {
        VStack(spacing: 14) {
            ForEach(availableFormats) { item in
                SelectionCard(
                    title: item.title,
                    detail: item.detail,
                    emoji: item.emoji,
                    isSelected: item == format
                ) {
                    format = item
                }
            }
        }
    }

    private var bankrollStep: some View {
        VStack(spacing: 24) {
            AppCard(accent: AppTheme.orange) {
                VStack(spacing: 14) {
                    Text("TOURNAMENT BANKROLL")
                        .font(.appMono(.caption))
                        .tracking(3)
                        .foregroundStyle(AppTheme.muted)
                    Text(Decimal(bankroll).currencyText)
                        .font(.oswald(74, weight: .bold))
                        .minimumScaleFactor(0.7)
                    Text(riskLabel)
                        .font(.oswald(22, weight: .bold))
                        .foregroundStyle(AppTheme.orange)
                    Text("Kept separate from every other tournament")
                        .font(.appMono(.caption))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("$100")
                    Spacer()
                    Text("$10,000")
                }
                .font(.appMono(.caption))
                .foregroundStyle(AppTheme.muted)
                Slider(value: $bankroll, in: 100...10_000, step: 50)
                    .tint(AppTheme.orange)
                HStack {
                    ForEach([250, 500, 1_000, 2_500, 5_000], id: \.self) { value in
                        Button {
                            bankroll = Double(value)
                        } label: {
                            Text(value >= 1_000 ? "$\(value / 1_000)K" : "$\(value)")
                                .font(.appMono(.caption))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Int(bankroll) == value ? AppTheme.orange.opacity(0.2) : AppTheme.surface,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Int(bankroll) == value ? AppTheme.orange : AppTheme.border)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("EXPECTED HIT RATE")
                                .font(.appMono(.caption))
                                .foregroundStyle(AppTheme.muted)
                            Text("\(Int(hitRate))%")
                                .font(.oswald(38, weight: .bold))
                                .foregroundStyle(AppTheme.orange)
                        }
                        Spacer()
                        Text("Used for Expected Value across the whole tournament.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 190)
                    }
                    Slider(value: $hitRate, in: 30...85, step: 1)
                        .tint(AppTheme.orange)
                        .accessibilityLabel("Expected hit rate")
                        .accessibilityValue("\(Int(hitRate)) percent")
                }
            }

            HStack(spacing: 12) {
                WizardMetric(title: "Max Stake", value: (Decimal(bankroll) * Decimal(0.05)).currencyText)
                WizardMetric(title: "Recommended Bets", value: "\(max(4, Int(bankroll / 125)))")
            }
        }
    }

    private var availableFormats: [BracketFormat] {
        switch sport {
        case .worldCup, .euro:
            BracketFormat.allCases
        case .nba, .nhl, .grandSlam:
            [.playoffs, .roundRobin]
        }
    }

    private var riskLabel: String {
        switch bankroll {
        case ..<500: "Conservative Plan"
        case 500..<2_500: "Moderate Risk"
        default: "High-Capacity Plan"
        }
    }

    private func goBack() {
        if step == 0 {
            dismiss()
        } else {
            step -= 1
        }
    }

    private func createTournament() {
        let tournament = TournamentFactory.make(
            sport: sport,
            format: format,
            bankroll: Decimal(bankroll),
            hitRate: hitRate / 100
        )
        store.add(tournament)
        dismiss()
    }
}

private struct WizardProgress: View {
    let step: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                VStack(spacing: 8) {
                    Capsule()
                        .fill(index <= step ? AppTheme.orange : AppTheme.raisedSurface)
                        .frame(height: 5)
                    Text(["SELECT SPORT", "BRACKET FORMAT", "BANKROLL"][index])
                        .font(.appMono(.caption2))
                        .foregroundStyle(index == step ? AppTheme.orange : AppTheme.muted)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct SelectionCard: View {
    let title: String
    let detail: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppCard(accent: isSelected ? AppTheme.orange : nil) {
                HStack(spacing: 18) {
                    EmojiBadge(
                        emoji: emoji,
                        size: 58,
                        tint: isSelected ? AppTheme.orange : AppTheme.muted
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.oswald(26, weight: .bold))
                            .foregroundStyle(.white)
                        Text(detail)
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? AppTheme.orange : AppTheme.muted)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct WizardMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.oswald(30, weight: .bold))
                .foregroundStyle(AppTheme.orange)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))
    }
}
