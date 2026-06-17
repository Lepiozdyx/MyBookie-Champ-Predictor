import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color.black
    static let surface = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let raisedSurface = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let orange = Color(red: 1, green: 0.40, blue: 0)
    static let green = Color(red: 0, green: 0.90, blue: 0.46)
    static let red = Color(red: 1, green: 0.24, blue: 0)
    static let muted = Color.white.opacity(0.42)
    static let border = Color.white.opacity(0.10)
}

extension Font {
    static func oswald(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Oswald", size: size, relativeTo: .body).weight(weight)
    }

    static func appMono(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .monospaced)
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    var backAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .frame(width: 52, height: 52)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow.uppercased())
                    .font(.appMono(.caption))
                    .tracking(3)
                    .foregroundStyle(AppTheme.orange)
                Text(title.uppercased())
                    .font(.oswald(42, weight: .bold))
                    .minimumScaleFactor(0.72)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }
}

struct AppCard<Content: View>: View {
    var accent: Color? = nil
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(accent?.opacity(0.45) ?? AppTheme.border)
            )
    }
}

struct EmojiBadge: View {
    let emoji: String
    var size: CGFloat = 54
    var tint: Color = AppTheme.orange

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.52))
            .frame(width: size, height: size)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.28))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28)
                    .stroke(tint.opacity(0.26))
            )
            .accessibilityHidden(true)
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol: String?
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title.uppercased())
                    .font(.oswald(24, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(isDisabled ? AppTheme.raisedSurface : AppTheme.orange)
            .foregroundStyle(isDisabled ? AppTheme.muted : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

enum AssetScaleMode {
    case cover
    case contain
    case fill
}

struct AssetArtwork: View {
    let name: String
    var mode: AssetScaleMode = .contain

    var body: some View {
        Group {
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .modifier(AssetScaleModifier(mode: mode))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.raisedSurface)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(AppTheme.orange.opacity(0.7))
                    Text(name)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.55)
                        .lineLimit(3)
                        .padding(6)
                }
            }
        }
        .clipped()
        .accessibilityLabel("Artwork: \(name)")
    }
}

private struct AssetScaleModifier: ViewModifier {
    let mode: AssetScaleMode

    @ViewBuilder
    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill()
        case .contain:
            content.scaledToFit()
        case .fill:
            content
        }
    }
}

extension Decimal {
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.positiveFormat = "$#,##0.##"
        formatter.negativeFormat = "-$#,##0.##"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = self == rounded(0) ? 0 : 2
        return formatter.string(from: self as NSDecimalNumber) ?? "$0"
    }

    private func rounded(_ scale: Int) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }
}

extension Double {
    var percentageText: String {
        String(format: "%+.1f%%", self)
    }
}
