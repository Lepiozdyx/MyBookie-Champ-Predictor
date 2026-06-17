import SwiftUI

private struct StrategyTip: Identifiable {
    let id: String
    let title: String
    let body: String
    let summary: String
}

private struct StrategyCategory: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let color: Color
    let tips: [StrategyTip]
}

struct StrategyGuideView: View {
    @EnvironmentObject private var store: TournamentStore
    @State private var expandedCategoryID: String?
    @State private var expandedTipID: String?
    @State private var openedTournament: Tournament?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(eyebrow: "Education Center", title: "Strategy Guide")

                    guideSummary

                    ForEach(categories) { category in
                        StrategyCategoryCard(
                            category: category,
                            isExpanded: expandedCategoryID == category.id,
                            expandedTipID: expandedTipID,
                            onCategoryToggle: { toggleCategory(category.id) },
                            onTipToggle: toggleTip
                        )
                    }

                    applyCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 44)
            }
            .background(AppTheme.background)
            .navigationDestination(item: $openedTournament) { tournament in
                TournamentDetailView(tournamentID: tournament.id)
            }
        }
    }

    private var guideSummary: some View {
        HStack(spacing: 10) {
            GuideMetric(title: "Categories", value: "\(categories.count)")
            GuideMetric(title: "Pro Tips", value: "\(categories.flatMap(\.tips).count)")
            GuideMetric(title: "Read Time", value: "~12 min")
            GuideMetric(title: "Difficulty", value: "Pro")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.border))
    }

    private var applyCard: some View {
        Button {
            guard let tournament = store.selectedTournament else { return }
            openedTournament = tournament
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "book")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 58, height: 58)
                    .background(AppTheme.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 17))

                VStack(alignment: .leading, spacing: 3) {
                    Text("APPLY TO YOUR BRACKET")
                        .font(.oswald(24, weight: .bold))
                        .foregroundStyle(.white)
                    Text(
                        store.selectedTournament == nil
                            ? "Create a tournament to apply these strategies."
                            : "Open your active tournament and build a smarter roadmap using these strategies."
                    )
                    .font(.appMono(.caption))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if store.selectedTournament != nil {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppTheme.orange.opacity(store.selectedTournament == nil ? 0.22 : 0.48))
            )
        }
        .buttonStyle(.plain)
        .disabled(store.selectedTournament == nil)
        .accessibilityHint(
            store.selectedTournament == nil
                ? "Create a tournament first"
                : "Opens the selected tournament"
        )
    }

    private func toggleCategory(_ id: String) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if expandedCategoryID == id {
                expandedCategoryID = nil
                expandedTipID = nil
            } else {
                expandedCategoryID = id
                expandedTipID = nil
            }
        }
    }

    private func toggleTip(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedTipID = expandedTipID == id ? nil : id
        }
    }

    private var categories: [StrategyCategory] {
        [
            StrategyCategory(
                id: "bankroll",
                title: "Bankroll Management",
                symbol: "dollarsign",
                color: AppTheme.orange,
                tips: [
                    StrategyTip(
                        id: "bankroll-isolation",
                        title: "Isolate the Tournament Bank",
                        body: "Keep the tournament bankroll separate from ordinary weekend bets. If you allocate $500 to a World Cup or playoff run, every planned stake for that competition must come from that fixed amount.",
                        summary: "One tournament. One protected bankroll."
                    ),
                    StrategyTip(
                        id: "fixed-units",
                        title: "Use Fixed-Percentage Units",
                        body: "Set every match stake as a consistent 1–3% of the tournament bankroll, regardless of how confident a prediction feels. Fixed sizing prevents one opinion from consuming the plan.",
                        summary: "Let the bankroll set the stake, not confidence."
                    ),
                    StrategyTip(
                        id: "no-chasing",
                        title: "Never Chase a Loss",
                        body: "A group-stage loss is not a reason to double the stake in the next knockout round. Chasing changes the risk model and turns a planned tournament into emotional betting.",
                        summary: "A lost bet does not justify a larger next bet."
                    ),
                    StrategyTip(
                        id: "protect-profit",
                        title: "Protect Mid-Tournament Profit",
                        body: "When the tournament reaches its midpoint in profit, lock in part of the gain or reduce the unit size. This keeps early success from being fully exposed during later rounds.",
                        summary: "Preserve profit before increasing late-stage risk."
                    )
                ]
            ),
            StrategyCategory(
                id: "stages",
                title: "Tournament Stages",
                symbol: "scope",
                color: AppTheme.green,
                tips: [
                    StrategyTip(
                        id: "group-caution",
                        title: "Start Groups Cautiously",
                        body: "Opening group matches produce more surprises and favorites may begin below full intensity. Reduce early stakes until form, lineups, and tournament rhythm become clearer.",
                        summary: "Use smaller stakes while early-stage information is noisy."
                    ),
                    StrategyTip(
                        id: "motivation",
                        title: "Read Qualification Motivation",
                        body: "In the final group round, identify which team needs a draw, which must win, and which has already qualified. Tournament incentives can matter more than nominal team strength.",
                        summary: "The standings define what each team actually needs."
                    ),
                    StrategyTip(
                        id: "hedge",
                        title: "Hedge a Deep Winner Pick",
                        body: "If a long-term tournament winner reaches the final, consider a measured bet on the opponent. The hedge can secure part of the projected profit without discarding the original position.",
                        summary: "Protect a successful futures path at the finish."
                    ),
                    StrategyTip(
                        id: "fresh-legs",
                        title: "Account for Fresh Legs",
                        body: "When teams play every three days, fatigue often encourages slower and more conservative football. Review rest and rotation before considering lower-total outcomes.",
                        summary: "Compressed schedules can suppress scoring."
                    )
                ]
            ),
            StrategyCategory(
                id: "psychology",
                title: "Betting Psychology",
                symbol: "brain.head.profile",
                color: Color(red: 1, green: 0.72, blue: 0),
                tips: [
                    StrategyTip(
                        id: "national-bias",
                        title: "Remove National Bias",
                        body: "Do not select your national team simply because of loyalty or emotion. Compare the same performance and matchup evidence you would require for any other team.",
                        summary: "Support is emotional; a prediction needs evidence."
                    ),
                    StrategyTip(
                        id: "recency-bias",
                        title: "Avoid the Recency Bias Trap",
                        body: "Do not overvalue a team because it won its last match convincingly. Evaluate the wider performance, the quality of the opponent, and whether the result is repeatable.",
                        summary: "One strong match should not rewrite the whole forecast."
                    ),
                    StrategyTip(
                        id: "short-variance",
                        title: "Respect Short-Run Variance",
                        body: "A seven-match tournament is a short sample. Form and random events can outweigh long-run mathematical expectations, even when the original reasoning was sound.",
                        summary: "Good analysis can still lose over a short tournament."
                    ),
                    StrategyTip(
                        id: "no-locks",
                        title: "Reject “Lock” Predictions",
                        body: "A penalty, red card, or single deflection can break a logical knockout prediction. Treat every outcome as uncertain and keep the stake inside the planned limit.",
                        summary: "No match is certain enough to ignore risk."
                    )
                ]
            ),
            StrategyCategory(
                id: "analytics",
                title: "Analytics & Market Insights",
                symbol: "chart.bar.fill",
                color: Color(red: 0, green: 0.68, blue: 0.94),
                tips: [
                    StrategyTip(
                        id: "line-movement",
                        title: "Track Line Movement",
                        body: "A sharp odds drop before a match may reflect an injury, lineup news, or informed market activity. Investigate the reason before changing the plan.",
                        summary: "Treat price movement as a prompt to research."
                    ),
                    StrategyTip(
                        id: "compare-odds",
                        title: "Compare Available Odds",
                        body: "A difference of 0.10 in decimal price becomes meaningful across twenty tournament bets. Record and compare prices before committing a prediction.",
                        summary: "Small price advantages compound across the tournament."
                    ),
                    StrategyTip(
                        id: "referees",
                        title: "Study Referee Style",
                        body: "Some referees allow physical play while others call frequent fouls. Their approach can materially affect cards, penalties, and total-related expectations.",
                        summary: "The official changes the match environment."
                    ),
                    StrategyTip(
                        id: "weather",
                        title: "Check Match Conditions",
                        body: "Heavy rain or strong wind can reduce finishing quality and overall scoring in elimination matches. Include weather in the pre-match assessment.",
                        summary: "Bad conditions can favor lower-scoring outcomes."
                    ),
                    StrategyTip(
                        id: "head-to-head",
                        title: "Review Head-to-Head Patterns",
                        body: "Some teams remain tactically or psychologically difficult opponents for a favorite. Use repeated head-to-head patterns as context for the current matchup.",
                        summary: "A persistent matchup problem can challenge the favorite."
                    ),
                    StrategyTip(
                        id: "favorite-pricing",
                        title: "Question Famous Favorites",
                        body: "Public money often backs well-known teams and shortens their odds. Compare reputation with the actual probability and look for value on an underdog with a handicap.",
                        summary: "A likely winner is not automatically a valuable price."
                    ),
                    StrategyTip(
                        id: "second-away",
                        title: "Watch the Second Road Match",
                        body: "Teams playing a second consecutive playoff road game can perform worse after halftime. Add travel sequence and late-game fatigue to the matchup notes.",
                        summary: "Repeated travel can reveal second-half weakness."
                    ),
                    StrategyTip(
                        id: "review-plan",
                        title: "Review the Plan Every Round",
                        body: "A tournament bracket changes as real results arrive. Update participants, odds, and future predictions after each round instead of forcing the original draft onto new facts.",
                        summary: "Adapt the roadmap to reality, not emotion."
                    )
                ]
            )
        ]
    }
}

private struct GuideMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.oswald(27, weight: .bold))
                .foregroundStyle(AppTheme.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StrategyCategoryCard: View {
    let category: StrategyCategory
    let isExpanded: Bool
    let expandedTipID: String?
    let onCategoryToggle: () -> Void
    let onTipToggle: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onCategoryToggle) {
                HStack(spacing: 16) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(category.color)
                        .frame(width: 58, height: 58)
                        .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 17))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(category.color.opacity(0.26))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title)
                            .font(.oswald(27, weight: .bold))
                            .foregroundStyle(.white.opacity(isExpanded ? 1 : 0.78))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text("\(category.tips.count) tips")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isExpanded ? category.color : AppTheme.muted)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                Divider().overlay(Color.white.opacity(0.06))

                VStack(spacing: 10) {
                    ForEach(Array(category.tips.enumerated()), id: \.element.id) { index, tip in
                        StrategyTipRow(
                            number: index + 1,
                            tip: tip,
                            color: category.color,
                            isExpanded: expandedTipID == tip.id,
                            onToggle: { onTipToggle(tip.id) }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isExpanded ? category.color.opacity(0.34) : AppTheme.border)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct StrategyTipRow: View {
    let number: Int
    let tip: StrategyTip
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Text(String(format: "%02d", number))
                        .font(.appMono(.caption))
                        .foregroundStyle(isExpanded ? color : AppTheme.muted)
                        .frame(width: 40, height: 40)
                        .background(
                            isExpanded ? color.opacity(0.14) : Color.white.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 11)
                        )

                    Text(tip.title)
                        .font(.oswald(22, weight: .semibold))
                        .foregroundStyle(.white.opacity(isExpanded ? 1 : 0.73))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)

                    Spacer(minLength: 6)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isExpanded ? color : AppTheme.muted)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 66)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text(tip.body)
                        .font(.system(.body, design: .default))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.body)
                            .foregroundStyle(color)
                            .padding(.top, 1)
                        Text(tip.summary)
                            .font(.appMono(.callout))
                            .foregroundStyle(color)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color.opacity(0.075), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(color.opacity(0.34))
                    )
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
            }
        }
        .background(
            isExpanded ? color.opacity(0.045) : AppTheme.raisedSurface,
            in: RoundedRectangle(cornerRadius: 17)
        )
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}
