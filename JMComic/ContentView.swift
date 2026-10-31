import SwiftUI
import SafariServices

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
        .sheet(isPresented: Binding(get: { state.safariURL != nil }, set: { if !$0 { state.safariURL = nil } })) {
            if let url = state.safariURL {
                SafariBrowserView(url: url).ignoresSafeArea()
            }
        }
        .alert("提示", isPresented: Binding(get: { state.notice != nil }, set: { if !$0 { state.notice = nil } })) {
            Button("知道了", role: .cancel) { state.notice = nil }
        } message: {
            Text(state.notice ?? "")
        }
    }
}

struct SafariBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

#Preview {
    ContentView().environmentObject(AppState())
}
