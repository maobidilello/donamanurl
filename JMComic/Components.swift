import SwiftUI
import UIKit

extension Color {
    static let appBlue = Color(red: 0.086, green: 0.541, blue: 1)
    static let appGold = Color(red: 0.898, green: 0.678, blue: 0.212)
    static let appBackground = Color(red: 0.969, green: 0.973, blue: 0.98)
    static let appSecondary = Color(red: 0.56, green: 0.58, blue: 0.62)
}

extension Int64 {
    var compactChinese: String {
        if self >= 100_000_000 { return String(format: "%.2f亿", Double(self) / 100_000_000) }
        if self >= 10_000 { return String(format: "%.2f万", Double(self) / 10_000) }
        return String(self)
    }
}

struct BundledAssetImage: View {
    let assetName: String
    let path: String

    private var bundledName: String {
        assetName.isEmpty ? URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent : assetName
    }

    var body: some View {
        if UIImage(named: bundledName) != nil {
            Image(bundledName).resizable().scaledToFill()
        } else {
            placeholder(systemName: "book.closed")
        }
    }

    private func placeholder(systemName: String) -> some View {
        Image(systemName: systemName).font(.largeTitle).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.gray.opacity(0.1))
    }
}

struct ComicCard: View {
    let comic: Comic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                BundledAssetImage(assetName: comic.assetName, path: comic.cover)
                    .aspectRatio(3 / 4.12, contentMode: .fit)
                    .clipped()
                Text(comic.title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                Text(String(format: "%.1f 分", comic.score))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appGold)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("打开\(comic.title)，评分\(String(format: "%.1f", comic.score))")
    }
}

struct SectionHeader: View {
    let title: String
    let symbol: String
    var color: Color = .appBlue
    var more: (() -> Void)?

    var body: some View {
        HStack {
            Label(title, systemImage: symbol).font(.title3.weight(.semibold)).foregroundStyle(color)
            Spacer()
            if let more {
                Button(action: more) {
                    Label("查看更多", systemImage: "chevron.right").font(.subheadline)
                }.foregroundStyle(Color.appSecondary)
            }
        }
    }
}

struct EmptyState: View {
    let title: String
    var description = "去首页发现喜欢的漫画吧"
    var systemImage = "books.vertical"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(.secondary)
                .frame(width: 76, height: 76).background(Color.gray.opacity(0.08)).clipShape(Circle())
            Text(title).font(.headline)
            Text(description).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 70)
    }
}

/// iOS 15 兼容的详情导航：用 NavigationLink 还原路径导航行为。
struct ComicDetailNavigation: View {
    @Binding var path: [Comic]

    private var isActive: Binding<Bool> {
        Binding(
            get: { !path.isEmpty },
            set: { active in
                if !active { path.removeAll() }
            }
        )
    }

    var body: some View {
        NavigationLink(destination: destination, isActive: isActive) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var destination: some View {
        if let comic = path.last {
            ComicDetailView(comic: comic)
        } else {
            EmptyView()
        }
    }
}

struct LoadingGrid: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(0..<9, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).aspectRatio(0.58, contentMode: .fit)
            }
        }
    }
}
