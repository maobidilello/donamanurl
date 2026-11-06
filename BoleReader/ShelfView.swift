import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var state: AppState
    @State private var path: [Book] = []
    @State private var editing = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationView {
            ScrollView {
                if state.favorites.isEmpty {
                    EmptyState(title: "书架还是空的", description: "喜欢的作品加入书架，下次接着看")
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("共 \(state.favorites.count) 部作品\(editing ? " · 点击减号移除" : " · 长按可管理")")
                            .font(.caption).foregroundStyle(.secondary)
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(state.favorites) { book in
                                BookCard(book: book) {
                                    path.append(book)
                                }
                                .overlay(alignment: .topTrailing) {
                                    if editing {
                                        Button {
                                            state.toggleFavorite(book)
                                        } label: {
                                            Image(systemName: "minus.circle.fill").font(.title2).foregroundStyle(.white, .red).padding(6)
                                        }
                                        .accessibilityLabel("移出\(book.title)")
                                    }
                                }
                                .contextMenu {
                                    Button("移出书架", role: .destructive) { state.toggleFavorite(book) }
                                }
                            }
                        }
                    }.padding(18)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("书架")
            .toolbar {
                Button(editing ? "完成" : "管理") { editing.toggle() }
                    .disabled(state.favorites.isEmpty)
            }
            .background(BookDetailNavigation(path: $path))
        }
    }
}

#Preview {
    ShelfView().environmentObject(AppState())
}
