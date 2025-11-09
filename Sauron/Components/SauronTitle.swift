import SwiftUI

// Reusable SAURON title styled per brand
struct SauronTitle: View {
    var size: CGFloat = 74

    var body: some View {
        Text("SAURON")
            .font(.custom("CinzelRoman-Bold", size: size))
            .foregroundColor(Brand.accent)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    SauronTitle()
        .frame(width: 400, height: 120)
        .background(Color.black)
}
