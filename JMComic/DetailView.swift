import SwiftUI

struct ComicDetailView: View {
    @EnvironmentObject private var state: AppState
    @State private var comic: Comic
    @State private var showingRating = false
    @State private var draftRating = 0

    init(comic: Comic) {
        _comic = State(initialValue: comic)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 18) {
                        Text(comic.title).font(.title.weight(.semibold))
                        Text("作者：\(comic.author)").font(.subheadline).foregroundStyle(.secondary).padding(.top, -12)
                        stats
                        Text("\(comic.status) | 更新：\(comic.updateTime) | \(comic.latestChapter)")
                            .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Text(comic.category).font(.caption).foregroundStyle(Color.appBlue).padding(.horizontal, 10).padding(.vertical, 5).background(Color.appBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 10) {
                            Text("简介").font(.title3.weight(.semibold))
                            Text(comic.description).font(.body).foregroundStyle(.secondary).lineSpacing(5)
                        }.padding(.top, 8)
                        Button { withAnimation { proxy.scrollTo("chapters", anchor: .top) } } label: {
                            Text(state.isFavorite(comic.id) ? "继续阅读" : "开始阅读").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(Color.appBlue).clipShape(Capsule())
                        }
                        chapterList.id("chapters")
                    }
                    .padding(22)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .offset(y: -12)
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle("漫画详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { draftRating = state.ratings[comic.id] ?? 0; showingRating = true } label: {
                    Image(systemName: state.ratings[comic.id] == nil ? "star" : "star.fill")
                }.accessibilityLabel("评价漫画")
                Button { state.toggleFavorite(comic) } label: {
                    Image(systemName: state.isFavorite(comic.id) ? "bookmark.fill" : "bookmark")
                }.accessibilityLabel(state.isFavorite(comic.id) ? "移出书架" : "加入书架")
            }
        }
        .task {
            if let loaded = await state.detail(id: comic.id) { comic = loaded }
            state.recordHistory(comic)
        }
        .sheet(isPresented: $showingRating) {
            VStack(spacing: 24) {
                Text("为《\(comic.title)》评分").font(.headline).padding(.top, 28)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { score in
                        Button { draftRating = score } label: {
                            Image(systemName: score <= draftRating ? "star.fill" : "star").font(.largeTitle).foregroundStyle(Color.appGold)
                        }.accessibilityLabel("\(score)星")
                    }
                }
                Button("确认评分") {
                    guard draftRating > 0 else { return }
                    state.rate(comic, score: draftRating)
                    showingRating = false
                }.buttonStyle(.borderedProminent).disabled(draftRating == 0)
                Spacer()
            }
        }
    }

    private var hero: some View {
        ZStack {
            BundledAssetImage(assetName: comic.assetName, path: comic.cover).blur(radius: 24).overlay(Color.black.opacity(0.35))
            BundledAssetImage(assetName: comic.assetName, path: comic.cover)
                .frame(width: 150, height: 205)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 3))
                .shadow(radius: 12)
        }.frame(maxWidth: .infinity).frame(height: 280).clipped()
    }

    private var stats: some View {
        HStack {
            stat(symbol: "star.fill", color: .appGold, value: String(format: "%.1f", comic.score), caption: "评分")
            stat(symbol: "heart.fill", color: .pink, value: comic.favorites.compactChinese, caption: "收藏")
            stat(symbol: "flame.fill", color: .orange, value: comic.popularity.compactChinese, caption: "人气")
        }.padding(.vertical, 14).background(Color.gray.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stat(symbol: String, color: Color, value: String, caption: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(value).font(.headline)
            Text(caption).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("章节列表").font(.headline)
                Spacer()
                Text("共 \(comic.chapters?.count ?? 0) 话").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(comic.chapters ?? []) { chapter in
                    Button(chapter.title) { state.notice = "已选择\(chapter.title)，正文内容等待作者更新" }
                        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.gray.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }.padding(.top, 10)
    }
}
