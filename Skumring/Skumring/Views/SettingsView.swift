import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    @State private var showYouTubeLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            youtubeSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Settings")
                .font(.largeTitle.bold())
            Spacer()
            Button("Done") {
                appModel.showSettingsSheet = false
            }
            .keyboardShortcut(.cancelAction)
        }
    }

    private var youtubeSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sign in to YouTube Premium to remove ads in playback.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showYouTubeLogin.toggle()
                } label: {
                    Label(showYouTubeLogin ? "Hide YouTube Login" : "Open YouTube Login", systemImage: "person.crop.circle")
                }
                .buttonStyle(.bordered)

                if showYouTubeLogin {
                    YouTubeLoginView()
                        .frame(maxWidth: .infinity, minHeight: 420, maxHeight: 520)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("YouTube")
        }
        .animation(.easeInOut(duration: 0.2), value: showYouTubeLogin)
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
