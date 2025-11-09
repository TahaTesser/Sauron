import SwiftUI

// Reusable primary button styled per brand
struct SauronPrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("IBMPlexMono-Bold", size: 14))
                .padding(.horizontal, 44)
                .padding(.vertical, 14)
                .foregroundColor(.black)
                .background(Brand.accent)
                .clipShape(Capsule())
                .shadow(color: Brand.accent.opacity(0.3), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack { Color.black }
        .overlay(
            SauronPrimaryButton(title: "Upload", action: {})
        )
        .frame(width: 300, height: 150)
}
