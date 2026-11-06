import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject private var state: AppState
    @State private var book: Book
    @State private var showingRating = false
    @State private var draftRating = 0
    @State private var readingChapter: Chapter?

    init(book: Book) {
        _book = State(initialValue: book)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 18) {
                        Text(book.title).font(.title.weight(.semibold))
                        Text("作者：\(book.author)").font(.subheadline).foregroundStyle(.secondary).padding(.top, -12)
                        stats
                        Text("\(book.status) | 更新：\(book.updateTime) | \(book.latestChapter)")
                            .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Text(book.category).font(.caption).foregroundStyle(Color.appBlue).padding(.horizontal, 10).padding(.vertical, 5).background(Color.appBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 10) {
                            Text("简介").font(.title3.weight(.semibold))
                            Text(book.description).font(.body).foregroundStyle(.secondary).lineSpacing(5)
                        }.padding(.top, 8)
                        Button { withAnimation { proxy.scrollTo("chapters", anchor: .top) } } label: {
                            Text(state.isFavorite(book.id) ? "继续阅读" : "开始阅读").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(Color.appBlue).clipShape(Capsule())
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
        .navigationTitle("作品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { draftRating = state.ratings[book.id] ?? 0; showingRating = true } label: {
                    Image(systemName: state.ratings[book.id] == nil ? "star" : "star.fill")
                }.accessibilityLabel("评价作品")
                Button { state.toggleFavorite(book) } label: {
                    Image(systemName: state.isFavorite(book.id) ? "bookmark.fill" : "bookmark")
                }.accessibilityLabel(state.isFavorite(book.id) ? "移出书架" : "加入书架")
            }
        }
        .task {
            if let loaded = await state.detail(id: book.id) { book = loaded }
            state.recordHistory(book)
        }
        .sheet(isPresented: $showingRating) {
            VStack(spacing: 24) {
                Text("为《\(book.title)》评分").font(.headline).padding(.top, 28)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { score in
                        Button { draftRating = score } label: {
                            Image(systemName: score <= draftRating ? "star.fill" : "star").font(.largeTitle).foregroundStyle(Color.appGold)
                        }.accessibilityLabel("\(score)星")
                    }
                }
                Button("确认评分") {
                    guard draftRating > 0 else { return }
                    state.rate(book, score: draftRating)
                    showingRating = false
                }.buttonStyle(.borderedProminent).disabled(draftRating == 0)
                Spacer()
            }
        }
        .sheet(item: $readingChapter) { chapter in
            ReaderSheet(book: book, chapter: chapter)
        }
    }

    private var hero: some View {
        ZStack {
            BundledAssetImage(assetName: book.assetName, path: book.cover).blur(radius: 24).overlay(Color.black.opacity(0.35))
            BundledAssetImage(assetName: book.assetName, path: book.cover)
                .frame(width: 150, height: 205)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 3))
                .shadow(radius: 12)
        }.frame(maxWidth: .infinity).frame(height: 280).clipped()
    }

    private var stats: some View {
        HStack {
            stat(symbol: "star.fill", color: .appGold, value: String(format: "%.1f", book.score), caption: "评分")
            stat(symbol: "heart.fill", color: .pink, value: book.favorites.compactChinese, caption: "收藏")
            stat(symbol: "flame.fill", color: .orange, value: book.popularity.compactChinese, caption: "人气")
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
                Text("共 \(book.chapters?.count ?? 0) 话").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(book.chapters ?? []) { chapter in
                    Button(chapter.title) { readingChapter = chapter }
                        .font(.caption).foregroundStyle(Color.appBlue).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.appBlue.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }.padding(.top, 10)
    }
}

struct ReaderSheet: View {
    let book: Book
    let chapter: Chapter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(chapter.title).font(.title2.weight(.bold))
                    Text(book.author).font(.subheadline).foregroundStyle(.secondary)
                    Divider()
                    Text(sampleText)
                        .font(.body)
                        .lineSpacing(8)
                        .foregroundStyle(.primary)
                }
                .padding(22)
            }
            .background(Color(.systemBackground))
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var sampleText: String {
        """
        清晨的第一缕阳光穿过窗帘，照在桌面上。

        他翻开手里那本旧书，纸页泛黄，字迹却依然清晰。窗外传来远处街道的嘈杂声，混着鸟鸣和自行车铃的叮当声。

        "今天会是怎样的一天呢？"他自言自语道。

        没有人回答。但他并不在意——很久以来，他已经习惯了和自己对话。

        书里夹着一张纸条，是很多年前写下的。上面只有一行字，墨迹已经褪成了浅褐色。他看了很久，然后轻轻把纸条放回原处。

        楼下传来敲门声。三下，停顿，又是三下。

        他站起身，走向门口。

        门外站着一个他从未见过的人，手里提着一个牛皮纸信封。

        "请问，这里是……"来人犹豫了一下，"林先生的住处吗？"

        他点了点头。

        来人把信封递过来："有人让我把这个交给您。他说，您看了就明白了。"

        信封很轻，几乎没有重量。但当他接过来的时候，却感觉像是接住了一段被遗忘很久的时光。

        他关上门，回到桌前，用裁纸刀小心地拆开信封。

        里面只有一张照片。

        照片上是两个少年，站在一棵很大的树下，笑得没心没肺。其中一个是他自己——那是二十年前的他。

        另一个人，他已经很多年没有见过了。

        照片背面写着一行字：

        "老地方，周六下午。别迟到。"
        """
    }
}
