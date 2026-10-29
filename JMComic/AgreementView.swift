import SwiftUI

struct AgreementView: View {
    let isPrivacy: Bool
    @Environment(\.dismiss) private var dismiss

    private var title: String { isPrivacy ? "隐私政策" : "用户协议" }
    private var document: String { isPrivacy ? TextResource.privacy : TextResource.userAgreement }

    var body: some View {
        ScrollView {
            Text(document)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .background(.white)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("关闭") { dismiss() } }
    }
}
