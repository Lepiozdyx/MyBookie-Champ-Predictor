import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case live = "Live"
    case analytics = "Analytics"
    case strategy = "Strategy"

    var symbol: String {
        switch self {
        case .home: "square.grid.2x2"
        case .live: "bolt.fill"
        case .analytics: "chart.bar.fill"
        case .strategy: "book"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: TournamentStore
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            Group {
                switch tab {
                case .home:
                    HomeView()
                case .live:
                    LiveView()
                case .analytics:
                    AnalyticsView()
                case .strategy:
                    StrategyGuideView()
                }
            }
            .padding(.bottom, 92)

            AppTabBar(selection: $tab)
        }
        .tint(AppTheme.orange)
    }
}

private struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                            .frame(width: 44, height: 36)
                            .background(
                                selection == tab ? AppTheme.orange.opacity(0.2) : .clear,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        Text(tab.rawValue.uppercased())
                            .font(.appMono(.caption2))
                    }
                    .foregroundStyle(selection == tab ? AppTheme.orange : AppTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(AppTheme.border))
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}
