import SwiftUI

struct MyBookieChampPredictorApp: View {
    @StateObject private var store = TournamentStore()

    var body: some View {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
    }
}
