import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var results: [Comic] = []
    @State private var searched = false
    @State private var loading = false
    @State private var path: [Comic] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var searchRevision = 0
    @FocusState private var focused: Bool
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("输入漫画名称或作者", text: $keyword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focused)
                            .submitLabel(.search)
                            .onSubmit(search)
                            .accessibilityIdentifier("comic-search-input")
                        if !keyword.isEmpty {
                            Button(action: clearSearch) { Image(systemName: "xmark.circle.fill") }.foregroundStyle(.secondary)
                        }
                    }
                    .padding(12).background(.white).clipShape(Capsule())

                    if loading {
                        ProgressView("正在搜索").frame(maxWidth: .infinity).padding(.top, 80)
                    } else if searched {
                        if results.isEmpty {
                            EmptyState(title: "没有找到你想要的？", description: "换个关键词再试试", systemImage: "magnifyingglass")
                        } else {
                            Text("找到 \(results.count) 部相关漫画").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(results) { comic in
                                    ComicCard(comic: comic) {
                                        path.append(comic)
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("搜索历史").font(.headline)
                                Spacer()
                                if !state.searchHistory.isEmpty { Button("清空") { state.clearSearchHistory() }.font(.subheadline) }
                            }
                            if state.searchHistory.isEmpty {
                                EmptyState(title: "暂无搜索记录", description: "试试搜索“雨夜符师”或作者名称", systemImage: "magnifyingglass")
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(state.searchHistory, id: \.self) { item in
                                            Button(item) { keyword = item; search() }
                                                .buttonStyle(.bordered).tint(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle("搜索漫画")
            .navigationBarTitleDisplayMode(.inline)
            .background(ComicDetailNavigation(path: $path))
            .toolbar { Button("关闭") { dismiss() } }
            .onAppear { focused = true }
            .onDisappear { searchTask?.cancel() }
        }
    }

    private func clearSearch() {
        searchTask?.cancel()
        searchRevision += 1
        keyword = ""
        results = []
        searched = false
        loading = false
    }

    private func search() {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()
        searchRevision += 1
        guard !value.isEmpty else {
            results = []
            searched = false
            loading = false
            return
        }
        let revision = searchRevision
        focused = false
        loading = true
        searched = true
        searchTask = Task {
            let matches = await state.search(value)
            guard !Task.isCancelled, revision == searchRevision else { return }
            results = matches
            loading = false
        }
    }
}

#Preview {
    SearchView().environmentObject(AppState())
}
