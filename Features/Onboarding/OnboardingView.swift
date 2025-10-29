import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
            Text("Discover hidden gems around you")
                .font(.title)
                .multilineTextAlignment(.center)
            Text("Capture a quick photo, add notes, and share with your groups. AI helps generate tags and details automatically.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
