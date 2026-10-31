import SwiftUI

enum MineSheet: Identifiable {
    case history, privacy, agreement, about, rate
    var id: String {
        switch self {
        case .history: "history"
        case .privacy: "privacy"
        case .agreement: "agreement"
        case .about: "about"
        case .rate: "rate"
        }
    }
}

struct MineView: View {
    @EnvironmentObject private var state: AppState
    @Binding var selection: Int
    @State private var sheet: MineSheet?
    @State private var draftRating = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 14) {
                        Image(systemName: "book.fill").font(.system(size: 38)).foregroundStyle(Color.appBlue)
                            .frame(width: 86, height: 86).background(Color.appBlue.opacity(0.1)).clipShape(Circle())
                        Text("啵乐漫画极速版").font(.title2.weight(.semibold))
                    }.frame(maxWidth: .infinity).padding(.vertical, 22).background(.white)
                    stats
                    VStack(spacing: 0) {
                        menuRow(icon: "star.fill", title: "评价应用") { draftRating = state.appRating; sheet = .rate }
                        menuRow(icon: "info.circle.fill", title: "关于", value: "v1.0.1") { sheet = .about }
                        menuRow(icon: "doc.text.fill", title: "用户协议") { sheet = .agreement }
                        menuRow(icon: "hand.raised.fill", title: "隐私政策") { sheet = .privacy }
                    }.background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    Text("无需注册或登录 · 收藏与浏览记录优先保存在本机")
                        .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
                }.padding(18)
            }
            .background(Color.appBackground)
            .navigationTitle("我的")
            .sheet(item: $sheet) { item in
                switch item {
                case .history: HistoryView()
                case .privacy: NavigationView { AgreementView(isPrivacy: true) }
                case .agreement: NavigationView { AgreementView(isPrivacy: false) }
                case .about: NavigationView { AboutView() }
                case .rate: appRatingSheet
                }
            }
        }
    }

    private var stats: some View {
        HStack {
            statButton(value: state.favorites.count, label: "我的收藏", icon: "heart.fill") { selection = 2 }
            statButton(value: state.history.count, label: "浏览历史", icon: "clock.fill") { sheet = .history }
            statButton(value: state.ratings.count, label: "我的评分", icon: "star.fill") {
                state.notice = state.ratings.isEmpty ? "在漫画详情页即可评分" : "已评价 \(state.ratings.count) 部漫画"
            }
        }.padding(.vertical, 18).background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statButton(value: Int, label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).foregroundStyle(Color.appBlue)
                Text("\(value)").font(.title3.weight(.semibold)).foregroundStyle(.primary)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }

    private func menuRow(icon: String, title: String, value: String = "", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).foregroundStyle(Color.appBlue).frame(width: 26)
                Text(title).foregroundStyle(.primary)
                Spacer()
                if !value.isEmpty { Text(value).foregroundStyle(.secondary) }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.padding(.horizontal, 18).frame(height: 62)
        }.buttonStyle(.plain)
    }

    private var appRatingSheet: some View {
        VStack(spacing: 24) {
            Text("喜欢 啵乐漫画极速版吗？").font(.title3.weight(.semibold)).padding(.top, 30)
            Text("你的鼓励是我们前进的动力").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { score in
                    Button { draftRating = score } label: {
                        Image(systemName: score <= draftRating ? "star.fill" : "star").font(.largeTitle).foregroundStyle(Color.appGold)
                    }
                }
            }
            Button("提交评价") { state.rateApp(draftRating); sheet = nil }.buttonStyle(.borderedProminent).disabled(draftRating == 0)
            Spacer()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "book.fill").font(.system(size: 44)).foregroundStyle(Color.appBlue).padding(.top, 32)
                Text("版本 1.0.1（101）").foregroundStyle(.secondary)
                Text(TextResource.about)
                    .font(.body)
                    .lineSpacing(7)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("关闭") { dismiss() } }
    }
}
