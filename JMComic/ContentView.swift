import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("首页", systemImage: "book") }
                .tag(0)
            RankView()
                .tabItem { Label("榜单", systemImage: "list.bullet") }
                .tag(1)
            ShelfView()
                .tabItem { Label("书架", systemImage: "books.vertical") }
                .tag(2)
            MineView(selection: $selection)
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
                .tag(3)
        }
        .background(Color.appBackground)
        .alert(state.redirectPrompt != nil ? "官方公告" : "提示", isPresented: Binding(
            get: { state.redirectPrompt != nil || state.notice != nil },
            set: { if !$0 { state.redirectPrompt = nil; state.notice = nil } }
        )) {
            if state.redirectPrompt != nil {
                Button("确认") { state.confirmRedirect() }
            } else {
                Button("知道了", role: .cancel) { state.notice = nil }
            }
        } message: {
            if let notice = state.notice { Text(notice) }
        }
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}
