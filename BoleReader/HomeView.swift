import SwiftUI

struct ListConfiguration: Identifiable, Hashable {
    var id: String { "\(mode.rawValue)-\(category)-\(completed)" }
    let mode: SortMode
    let category: String
    let completed: Bool
}

struct HomeView: View {
    @EnvironmentObject private var state: AppState
    @State private var category = "全部"
    @State private var path: [Book] = []
    @State private var showSearch = false
    @State private var selectedList: ListConfiguration?

    private var categories: [String] { ["全部"] + state.home.categories.map(\.name) }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 28) {
                    bannerPager
                    categorySelector
                    if let errorMessage = state.errorMessage {
                        Text(errorMessage).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    bookSection(title: "热门推荐", symbol: "flame.fill", color: .orange, books: state.home.hot, mode: .hot)
                    bookSection(title: "高分推荐", symbol: "star.fill", color: .appGold, books: state.home.topRated, mode: .rating)
                    bookSection(title: "最近更新", symbol: "clock.fill", color: .appBlue, books: state.home.recent, mode: .update)
                    if let daily = state.home.daily { dailyCard(daily) }
                    bookSection(title: "完结推荐", symbol: "checkmark.circle.fill", color: .green, books: state.home.completed, mode: .rating, completed: true)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("啵乐阅读").font(.headline)
                        Text(TextResource.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
                        .accessibilityLabel("搜索作品")
                }
            }
            .background(BookDetailNavigation(path: $path))
            .refreshable {
                await state.refreshHome(category: category)
            }
            .sheet(isPresented: $showSearch) { SearchView() }
            .sheet(item: $selectedList) { configuration in
                BookListView(configuration: configuration)
            }
        }
    }

    private var bannerPager: some View {
        TabView {
            ForEach(state.home.banners) { banner in
                Button {
                    Task {
                        guard let book = await state.detail(id: banner.bookID) else {
                            state.notice = "推荐内容不存在或已下架"
                            return
                        }
                        path.append(book)
                    }
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        BundledAssetImage(assetName: banner.assetName, path: banner.image)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开推荐：\(banner.title)")
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .tabViewStyle(.page(indexDisplayMode: .always))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { item in
                    Button {
                        category = item
                        Task { await state.refreshHome(category: item) }
                    } label: {
                        Text(item).font(.subheadline).padding(.horizontal, 22).padding(.vertical, 10)
                            .background(category == item ? Color.appBlue : .white)
                            .foregroundStyle(category == item ? .white : .secondary)
                            .clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func bookSection(title: String, symbol: String, color: Color, books: [Book], mode: SortMode, completed: Bool = false) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: title, symbol: symbol, color: color) {
                selectedList = ListConfiguration(mode: mode, category: category, completed: completed)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(books.prefix(10)) { book in
                        BookCard(book: book) { open(book) }.frame(width: 126)
                    }
                }.padding(.vertical, 4)
            }
        }
    }

    private func dailyCard(_ book: Book) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "每日推荐", symbol: "sparkles", color: .appGold)
            Button { open(book) } label: {
                HStack(alignment: .top, spacing: 16) {
                    BundledAssetImage(assetName: book.assetName, path: book.cover)
                        .frame(width: 100, height: 138).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("精选推荐").font(.caption).foregroundStyle(Color.appGold).padding(.horizontal, 8).padding(.vertical, 4).background(Color.appGold.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(book.title).font(.title3.weight(.semibold))
                        Text(book.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                        Spacer()
                        Text(String(format: "%.1f 分", book.score)).font(.subheadline.weight(.medium)).foregroundStyle(Color.appGold)
                    }
                    .frame(height: 138, alignment: .top)
                }
                .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain)
        }
    }

    private func open(_ book: Book) {
        path.append(book)
    }
}

struct BookListView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    let configuration: ListConfiguration
    @State private var books: [Book] = []
    @State private var path: [Book] = []
    @State private var loading = true
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    LoadingGrid().padding(18)
                } else {
                    let items = configuration.completed ? books.filter { $0.status == "已完结" } : books
                    if items.isEmpty {
                        EmptyState(title: "暂无相关作品")
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(items) { book in
                                    BookCard(book: book) {
                                        path.append(book)
                                    }
                                }
                            }.padding(18)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .navigationTitle(configuration.completed ? "完结推荐" : configuration.mode == .hot ? "热门推荐" : configuration.mode == .rating ? "高分推荐" : "最近更新")
            .navigationBarTitleDisplayMode(.inline)
            .background(BookDetailNavigation(path: $path))
            .task {
                books = await state.ranked(configuration.mode, category: configuration.category)
                loading = false
            }
            .toolbar { Button("关闭") { dismiss() } }
        }
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
