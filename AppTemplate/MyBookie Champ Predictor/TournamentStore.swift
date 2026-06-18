import Combine
import Foundation

@MainActor
final class TournamentStore: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var tournaments: [Tournament] = []
    @Published private(set) var loadState: LoadState = .loading
    @Published var selectedTournamentID: UUID?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = directory.appendingPathComponent("ChampPredictor", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("tournaments.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    var selectedTournament: Tournament? {
        guard let selectedTournamentID else { return tournaments.first }
        return tournaments.first { $0.id == selectedTournamentID } ?? tournaments.first
    }

    func add(_ tournament: Tournament) {
        tournaments.insert(tournament, at: 0)
        selectedTournamentID = tournament.id
        persist()
    }

    func update(_ tournament: Tournament) {
        guard let index = tournaments.firstIndex(where: { $0.id == tournament.id }) else { return }
        tournaments[index] = tournament
        persist()
    }

    func delete(_ tournament: Tournament) {
        tournaments.removeAll { $0.id == tournament.id }
        if selectedTournamentID == tournament.id {
            selectedTournamentID = tournaments.first?.id
        }
        persist()
    }

    func retryLoad() {
        load()
    }

    private func load() {
        loadState = .loading
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            tournaments = []
            loadState = .ready
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            tournaments = try decoder.decode([Tournament].self, from: data)
            selectedTournamentID = tournaments.first?.id
            loadState = .ready
        } catch {
            tournaments = []
            loadState = .failed("Saved tournaments could not be opened. You can retry without losing the file.")
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(tournaments)
            try data.write(to: fileURL, options: .atomic)
            loadState = .ready
        } catch {
            loadState = .failed("Your latest change could not be saved. Check available storage and try again.")
        }
    }
}
