import Charts
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: TournamentStore

    var body: some View {
        NavigationStack {
            if let tournament = store.selectedTournament {
                TournamentAnalyticsContent(tournamentID: tournament.id, showsBackButton: false)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ScreenHeader(eyebrow: "No Tournament Selected", title: "Analytics")
                        ContentUnavailableView {
                            Label("No Analytics Yet", systemImage: "chart.bar.xaxis")
                        } description: {
                            Text("Create a tournament and grade predictions to build your report.")
                        }
                        .frame(minHeight: 520)
                    }
                    .padding(20)
                }
                .background(AppTheme.background)
            }
        }
    }
}

struct TournamentAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    let tournamentID: UUID

    var body: some View {
        TournamentAnalyticsContent(
            tournamentID: tournamentID,
            showsBackButton: true,
            backAction: { dismiss() }
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TournamentAnalyticsContent: View {
    @EnvironmentObject private var store: TournamentStore
    let tournamentID: UUID
    var showsBackButton = false
    var backAction: (() -> Void)?
    @State private var chartMode: ChartMode = .bankroll

    private enum ChartMode: String, CaseIterable {
        case bankroll = "Bankroll Curve"
        case stages = "Stage Performance"
    }

    var body: some View {
        Group {
            if let tournament = store.tournaments.first(where: { $0.id == tournamentID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenHeader(
                            eyebrow: tournament.name,
                            title: "Analytics",
                            backAction: showsBackButton ? backAction : nil
                        )

                        HStack(spacing: 10) {
                            AnalyticsMetric(title: "Total ROI", value: tournament.roi.percentageText, color: tournament.roi >= 0 ? AppTheme.green : AppTheme.red)
                            AnalyticsMetric(title: "P&L", value: tournament.settledProfit.currencyText, color: tournament.settledProfit >= 0 ? AppTheme.green : AppTheme.red)
                            AnalyticsMetric(title: "Win Rate", value: "\(Int(winRate(tournament) * 100))%", color: AppTheme.orange)
                        }

                        AppCard {
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    ForEach(ChartMode.allCases, id: \.self) { mode in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.18)) {
                                                chartMode = mode
                                            }
                                        } label: {
                                            Text(mode.rawValue)
                                                .font(.appMono(.caption))
                                                .foregroundStyle(chartMode == mode ? AppTheme.orange : AppTheme.muted)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(
                                                    chartMode == mode
                                                        ? AppTheme.orange.opacity(0.16)
                                                        : AppTheme.raisedSurface,
                                                    in: RoundedRectangle(cornerRadius: 13)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 13)
                                                        .stroke(
                                                            chartMode == mode
                                                                ? AppTheme.orange.opacity(0.65)
                                                                : AppTheme.border
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityAddTraits(chartMode == mode ? .isSelected : [])
                                    }
                                }

                                if chartMode == .bankroll {
                                    BankrollChart(tournament: tournament)
                                } else {
                                    StageChart(tournament: tournament)
                                }
                            }
                        }

                        ReportCard(tournament: tournament)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(AppTheme.background)
    }

    private func winRate(_ tournament: Tournament) -> Double {
        let decided = tournament.matches.filter { [.win, .loss].contains($0.result) }
        guard !decided.isEmpty else { return 0 }
        return Double(decided.filter { $0.result == .win }.count) / Double(decided.count)
    }
}

private struct AnalyticsMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.oswald(27, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.52)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))
    }
}

private struct BankrollPoint: Identifiable {
    let id = UUID()
    let label: String
    let projected: Double
    let actual: Double
}

private struct BankrollChart: View {
    let tournament: Tournament

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 22) {
                ChartLegendLine(title: "Projected", color: AppTheme.orange, dashed: true)
                ChartLegendLine(title: "Actual", color: AppTheme.green, dashed: false)
            }

            Chart(points) { point in
                LineMark(
                    x: .value("Bet", point.label),
                    y: .value("Projected", point.projected)
                )
                .foregroundStyle(AppTheme.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .interpolationMethod(.linear)

                LineMark(
                    x: .value("Bet", point.label),
                    y: .value("Actual", point.actual)
                )
                .foregroundStyle(AppTheme.green)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Bet", point.label),
                    y: .value("Actual", point.actual)
                )
                .foregroundStyle(AppTheme.green)
                .symbolSize(26)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(axisCurrency(number))
                                .font(.appMono(.caption2))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: points.map(\.label)) {
                    AxisValueLabel()
                        .font(.appMono(.caption2))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
            .frame(height: 165)
            .accessibilityLabel("Projected and actual bankroll curve")
        }
    }

    private var points: [BankrollPoint] {
        var actual = NSDecimalNumber(decimal: tournament.bankroll).doubleValue
        var projected = actual
        var result = [BankrollPoint(label: "Start", projected: projected, actual: actual)]
        for (index, match) in tournament.plannedMatches.enumerated() {
            let expected = NSDecimalNumber(
                decimal: Decimal(tournament.expectedHitRate) * match.profitIfWin -
                (1 - Decimal(tournament.expectedHitRate)) * match.stake
            ).doubleValue
            projected += expected
            actual += NSDecimalNumber(decimal: match.settledProfit).doubleValue
            result.append(
                BankrollPoint(
                    label: chartLabel(for: match, index: index),
                    projected: projected,
                    actual: actual
                )
            )
        }
        return result
    }

    private func chartLabel(for match: TournamentMatch, index: Int) -> String {
        switch match.stage {
        case .roundOne: "R1G\(index + 1)"
        case .roundTwo: "R2G\(index + 1)"
        case .quarterfinal: "QF\(index + 1)"
        case .semifinal: "SF\(index + 1)"
        case .final: "Final"
        case .group: "G\(index + 1)"
        }
    }

    private func axisCurrency(_ value: Double) -> String {
        let absolute = abs(value)
        if absolute >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
                .replacingOccurrences(of: ".0", with: "")
        }
        return "$\(Int(value.rounded()))"
    }
}

private struct StageValue: Identifiable {
    var id: MatchStage { stage }
    let stage: MatchStage
    let winRate: Double
    let roi: Double
    let profit: Decimal
    let bets: Int
}

private struct StageChart: View {
    let tournament: Tournament

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 22) {
                ChartLegendSquare(title: "Win %", color: AppTheme.orange)
                ChartLegendSquare(title: "ROI %", color: AppTheme.green)
            }

            Chart(values) { item in
                BarMark(
                    x: .value("Stage", item.stage.rawValue),
                    y: .value("Win Rate", item.winRate)
                )
                .foregroundStyle(AppTheme.orange)
                .position(by: .value("Metric", "Win Rate"))
                .cornerRadius(4)

                BarMark(
                    x: .value("Stage", item.stage.rawValue),
                    y: .value("ROI", item.roi)
                )
                .foregroundStyle(AppTheme.green)
                .position(by: .value("Metric", "ROI"))
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let number = value.as(Int.self) {
                            Text("\(number)")
                                .font(.appMono(.caption2))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .font(.appMono(.caption2))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .chartYScale(domain: -15...100)
            .frame(height: 185)
            .accessibilityLabel("Win rate and return on investment by tournament stage")

            Divider().overlay(AppTheme.border)

            HStack {
                Text("")
                    .frame(width: 42)
                StageColumnHeader(title: "WIN%")
                StageColumnHeader(title: "ROI")
                StageColumnHeader(title: "P&L")
                StageColumnHeader(title: "BETS")
            }

            ForEach(values) { item in
                HStack {
                    Text(item.stage.rawValue)
                        .font(.appMono(.caption))
                        .foregroundStyle(AppTheme.muted)
                        .frame(width: 42, alignment: .leading)
                    Text("\(Int(item.winRate))%")
                        .foregroundStyle(AppTheme.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(stagePercentage(item.roi))
                        .foregroundStyle(item.roi >= 0 ? AppTheme.green : AppTheme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.profit.currencyText)
                        .foregroundStyle(item.profit >= 0 ? .white : AppTheme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(item.bets)")
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.appMono(.caption))
                .padding(.vertical, 7)
                if item.id != values.last?.id {
                    Divider().overlay(Color.white.opacity(0.06))
                }
            }
        }
    }

    private var values: [StageValue] {
        Dictionary(grouping: tournament.plannedMatches, by: \.stage)
            .compactMap { stage, matches in
                let settled = matches.filter { [.win, .loss, .push].contains($0.result) }
                guard !settled.isEmpty else { return nil }
                let wins = settled.filter { $0.result == .win }.count
                let invested = settled.reduce(Decimal.zero) { $0 + $1.stake }
                let profit = settled.reduce(Decimal.zero) { $0 + $1.settledProfit }
                let roi = invested > 0 ? NSDecimalNumber(decimal: profit / invested).doubleValue * 100 : 0
                return StageValue(
                    stage: stage,
                    winRate: Double(wins) / Double(settled.count) * 100,
                    roi: roi,
                    profit: profit,
                    bets: settled.count
                )
            }
            .sorted { stageOrder($0.stage) < stageOrder($1.stage) }
    }

    private func stageOrder(_ stage: MatchStage) -> Int {
        switch stage {
        case .group: 0
        case .roundOne: 1
        case .roundTwo: 2
        case .quarterfinal: 3
        case .semifinal: 4
        case .final: 5
        }
    }

    private func stagePercentage(_ value: Double) -> String {
        value > 0 ? String(format: "+%.1f%%", value) : String(format: "%.1f%%", value)
    }
}

private struct ChartLegendLine: View {
    let title: String
    let color: Color
    let dashed: Bool

    var body: some View {
        HStack(spacing: 7) {
            Capsule()
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 2, dash: dashed ? [4, 3] : [])
                )
                .frame(width: 20, height: 2)
            Text(title)
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
        }
    }
}

private struct ChartLegendSquare: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 11, height: 11)
            Text(title)
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
        }
    }
}

private struct StageColumnHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.appMono(.caption2))
            .foregroundStyle(AppTheme.muted.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReportCard: View {
    let tournament: Tournament

    var body: some View {
        AppCard(accent: AppTheme.orange) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "medal")
                        .font(.title2)
                        .foregroundStyle(AppTheme.orange)
                    VStack(alignment: .leading) {
                        Text("TOURNAMENT REPORT CARD")
                            .font(.oswald(25, weight: .bold))
                        Text("\(tournament.name) · \(tournament.isCompleted ? "Completed" : "In Progress")")
                            .font(.appMono(.caption))
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ReportMetric(title: "Total ROI", value: tournament.roi.percentageText, color: tournament.roi >= 0 ? AppTheme.green : AppTheme.red)
                    ReportMetric(title: "Best Bet", value: bestBetText, color: AppTheme.green)
                    ReportMetric(title: "Worst Decision", value: worstBetText, color: AppTheme.red)
                    ReportMetric(title: "Win Streak", value: "\(longestWinStreak) bets", color: AppTheme.orange)
                    ReportMetric(title: "Largest Drawdown", value: largestLoss.currencyText, color: AppTheme.red)
                    ReportMetric(title: "Bets Placed", value: "\(settledCount) / \(tournament.plannedMatches.count)", color: .white)
                }
            }
        }
    }

    private var bestBetText: String {
        tournament.matches
            .filter { $0.result == .win }
            .max(by: { $0.profitIfWin < $1.profitIfWin })?
            .selectedWinner?.shortName ?? "—"
    }

    private var worstBetText: String {
        tournament.matches
            .filter { $0.result == .loss }
            .max(by: { $0.stake < $1.stake })?
            .selectedWinner?.shortName ?? "—"
    }

    private var largestLoss: Decimal {
        tournament.matches.filter { $0.result == .loss }.map(\.stake).max() ?? 0
    }

    private var settledCount: Int {
        tournament.matches.filter { $0.result != .pending }.count
    }

    private var longestWinStreak: Int {
        var best = 0
        var current = 0
        for match in tournament.matches {
            if match.result == .win {
                current += 1
                best = max(best, current)
            } else if match.result == .loss {
                current = 0
            }
        }
        return best
    }
}

private struct ReportMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.appMono(.caption2))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.oswald(27, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
    }
}
