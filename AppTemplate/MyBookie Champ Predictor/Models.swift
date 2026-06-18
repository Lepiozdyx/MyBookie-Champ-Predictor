import Foundation

enum SportTemplate: String, Codable, CaseIterable, Identifiable {
    case worldCup
    case euro
    case nba
    case nhl
    case grandSlam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worldCup: "FIFA World Cup"
        case .euro: "UEFA Euro"
        case .nba: "NBA Playoffs"
        case .nhl: "NHL Playoffs"
        case .grandSlam: "Grand Slam"
        }
    }

    var detail: String {
        switch self {
        case .worldCup: "32 teams · 64 matches · 8 groups"
        case .euro: "24 teams · 51 matches · 6 groups"
        case .nba, .nhl: "16 teams · 4 rounds · Best of 7"
        case .grandSlam: "128 players · 7 rounds · Knockout"
        }
    }

    var category: String {
        switch self {
        case .worldCup, .euro: "Football"
        case .nba: "Basketball"
        case .nhl: "Hockey"
        case .grandSlam: "Tennis"
        }
    }

    var emoji: String {
        switch self {
        case .worldCup: "🌍"
        case .euro: "⚽️"
        case .nba: "🏀"
        case .nhl: "🏒"
        case .grandSlam: "🎾"
        }
    }

    var assetName: String {
        switch self {
        case .worldCup: "tournament_world_cup_icon"
        case .euro: "tournament_euro_icon"
        case .nba: "tournament_nba_icon"
        case .nhl: "tournament_nhl_icon"
        case .grandSlam: "tournament_grand_slam_icon"
        }
    }
}

enum BracketFormat: String, Codable, CaseIterable, Identifiable {
    case groupPlayoffs
    case playoffs
    case roundRobin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .groupPlayoffs: "Group Stage + Playoffs"
        case .playoffs: "Playoffs Only"
        case .roundRobin: "Round Robin League"
        }
    }

    var detail: String {
        switch self {
        case .groupPlayoffs: "Group phase followed by knockout rounds"
        case .playoffs: "Pure knockout bracket from the first round"
        case .roundRobin: "Every team plays every other team"
        }
    }

    var emoji: String {
        switch self {
        case .groupPlayoffs: "🏆"
        case .playoffs: "⚡️"
        case .roundRobin: "🔄"
        }
    }
}

enum MatchStage: String, Codable, CaseIterable {
    case group = "Group"
    case roundOne = "R1"
    case roundTwo = "R2"
    case quarterfinal = "QF"
    case semifinal = "SF"
    case final = "Final"
}

enum PredictionResult: String, Codable, CaseIterable {
    case pending
    case win
    case loss
    case push
}

struct Team: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var shortName: String
}

struct TournamentMatch: Identifiable, Codable, Hashable {
    var id = UUID()
    var stage: MatchStage
    var label: String
    var home: Team
    var away: Team
    var scheduledAt: Date
    var selectedWinnerID: UUID?
    var actualWinnerID: UUID?
    var americanOdds: Int = -110
    var stake: Decimal = 0
    var notes: String = ""
    var result: PredictionResult = .pending

    var selectedWinner: Team? {
        [home, away].first { $0.id == selectedWinnerID }
    }

    var actualWinner: Team? {
        [home, away].first { $0.id == actualWinnerID }
    }

    var isPredictionComplete: Bool {
        selectedWinnerID != nil && stake > 0
    }

    var profitIfWin: Decimal {
        guard stake > 0 else { return 0 }
        if americanOdds > 0 {
            return stake * Decimal(americanOdds) / 100
        }
        return stake * 100 / Decimal(abs(americanOdds))
    }

    var settledProfit: Decimal {
        switch result {
        case .win: profitIfWin
        case .loss: -stake
        case .push, .pending: 0
        }
    }
}

struct TeamGroup: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var teams: [Team]
}

struct Tournament: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var sport: SportTemplate
    var format: BracketFormat
    var bankroll: Decimal
    var expectedHitRate: Double
    var createdAt = Date()
    var matches: [TournamentMatch]
    var groups: [TeamGroup]
    var isCompleted = false

    var invested: Decimal {
        matches.reduce(0) { $0 + $1.stake }
    }

    var settledProfit: Decimal {
        matches.reduce(0) { $0 + $1.settledProfit }
    }

    var balance: Decimal {
        bankroll + settledProfit
    }

    var roi: Double {
        guard invested > 0 else { return 0 }
        return NSDecimalNumber(decimal: settledProfit / invested).doubleValue * 100
    }

    var plannedMatches: [TournamentMatch] {
        matches.filter(\.isPredictionComplete)
    }

    var affectedMatches: [TournamentMatch] {
        let eliminatedIDs = Set(matches.compactMap { match -> UUID? in
            guard match.result != .pending,
                  let actualWinnerID = match.actualWinnerID else { return nil }
            return actualWinnerID == match.home.id ? match.away.id : match.home.id
        })
        return matches.filter {
            $0.result == .pending &&
            (eliminatedIDs.contains($0.home.id) || eliminatedIDs.contains($0.away.id))
        }
    }
}

enum TournamentFactory {
    static func make(
        sport: SportTemplate,
        format: BracketFormat,
        bankroll: Decimal,
        hitRate: Double
    ) -> Tournament {
        let teams = mockTeams(for: sport)
        let matches = mockMatches(teams: teams, format: format)
        let groups = format == .groupPlayoffs ? mockGroups(teams: teams) : []
        return Tournament(
            name: "\(sport.title) 2028",
            sport: sport,
            format: format,
            bankroll: bankroll,
            expectedHitRate: hitRate,
            matches: matches,
            groups: groups
        )
    }

    private static func mockTeams(for sport: SportTemplate) -> [Team] {
        let names: [String]
        switch sport {
        case .worldCup:
            names = ["Argentina", "France", "Brazil", "Spain", "England", "Germany", "Portugal", "Netherlands"]
        case .euro:
            names = ["Spain", "England", "France", "Germany", "Portugal", "Italy", "Netherlands", "Croatia"]
        case .nba:
            names = ["Boston Celtics", "Miami Heat", "Cleveland Cavaliers", "Orlando Magic", "New York Knicks", "Philadelphia 76ers", "Milwaukee Bucks", "Indiana Pacers"]
        case .nhl:
            names = ["Florida Panthers", "Boston Bruins", "New York Rangers", "Carolina Hurricanes", "Dallas Stars", "Colorado Avalanche", "Edmonton Oilers", "Vancouver Canucks"]
        case .grandSlam:
            names = ["Jannik Sinner", "Carlos Alcaraz", "Novak Djokovic", "Daniil Medvedev", "Alexander Zverev", "Taylor Fritz", "Casper Ruud", "Andrey Rublev"]
        }
        return names.map { Team(name: $0, shortName: shortName(for: $0)) }
    }

    private static func mockMatches(teams: [Team], format: BracketFormat) -> [TournamentMatch] {
        guard teams.count >= 8 else { return [] }
        let calendar = Calendar.current
        let now = Date()
        var matches: [TournamentMatch] = []

        for index in stride(from: 0, to: 8, by: 2) {
            matches.append(
                TournamentMatch(
                    stage: format == .roundRobin ? .group : .roundOne,
                    label: format == .roundRobin ? "League Match \(index / 2 + 1)" : "R1 Game \(index / 2 + 1)",
                    home: teams[index],
                    away: teams[index + 1],
                    scheduledAt: calendar.date(byAdding: .day, value: index / 2, to: now) ?? now
                )
            )
        }

        guard format != .roundRobin else { return matches }
        matches.append(
            TournamentMatch(
                stage: .semifinal,
                label: "Semifinal 1",
                home: teams[0],
                away: teams[2],
                scheduledAt: calendar.date(byAdding: .day, value: 10, to: now) ?? now
            )
        )
        matches.append(
            TournamentMatch(
                stage: .semifinal,
                label: "Semifinal 2",
                home: teams[4],
                away: teams[6],
                scheduledAt: calendar.date(byAdding: .day, value: 11, to: now) ?? now
            )
        )
        matches.append(
            TournamentMatch(
                stage: .final,
                label: "Final",
                home: teams[0],
                away: teams[4],
                scheduledAt: calendar.date(byAdding: .day, value: 16, to: now) ?? now
            )
        )
        return matches
    }

    private static func mockGroups(teams: [Team]) -> [TeamGroup] {
        [
            TeamGroup(name: "Group A", teams: Array(teams.prefix(4))),
            TeamGroup(name: "Group B", teams: Array(teams.suffix(4)))
        ]
    }

    private static func shortName(for name: String) -> String {
        name.split(separator: " ")
            .prefix(3)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
