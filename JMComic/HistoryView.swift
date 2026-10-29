import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Comic] = []
    @State private var confirmingClear = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationView {
            ScrollView {
                if state.history.isEmpty {
                    EmptyState(title: "还没有浏览记录", description: "打开漫画详情后会自动记录", systemImage: "clock")
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(state.history) { comic in
                            ComicCard(comic: comic) {
                                path.append(comic)
                            }
                        }
                    }.padding(18)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("浏览历史")
            .navigationBarTitleDisplayMode(.inline)
            .background(ComicDetailNavigation(path: $path))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("清空") { confirmingClear = true }
                        .disabled(state.history.isEmpty)
                }
            }
            .confirmationDialog("确定清空全部浏览记录吗？", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { state.clearHistory() }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
