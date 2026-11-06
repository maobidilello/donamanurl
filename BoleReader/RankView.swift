import SwiftUI

struct RankView: View {
    @EnvironmentObject private var state: AppState
    @State private var mode = SortMode.hot
    @State private var books: [Book] = []
    @State private var loading = true
    @State private var path: [Book] = []
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    Picker("榜单类型", selection: $mode) {
                        ForEach(SortMode.allCases) { mode in Text(mode.title).tag(mode) }
                    }
                    .pickerStyle(.segmented)
                    if loading {
                        LoadingGrid()
                    } else if books.isEmpty {
                        EmptyState(title: "暂无榜单内容")
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(books) { book in
                                BookCard(book: book) {
                                    path.append(book)
                                }
                            }
                        }
                    }
                }.padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle("热门推荐")
            .background(BookDetailNavigation(path: $path))
            .task(id: mode) {
                loading = true
                books = await state.ranked(mode)
                loading = false
            }
        }
    }
}

#Preview {
    RankView().environmentObject(AppState())
}
