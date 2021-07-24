import Persist
import SwiftUI

struct IgnoredHostnamesView: View {
    @PersistStorage(
        persister: Persister(
            key: "ignoredHostnames",
            userDefaults: UserDefaults(suiteName: "group.net.yetii.overamped")!,
            defaultValue: []
        )
    )
    private(set) var ignoredHostnames: [String]

    var body: some View {
        Group {
            if ignoredHostnames.isEmpty {
                Text("No hostnames have been ignored")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.placeholderText))
            } else {
                List {
                    ForEach(ignoredHostnames, id: \.self) { ignoredHostname in
                        Text(ignoredHostname)
                    }
                    .onDelete(perform: deleteIgnoredHostnames(atOffsets:))
                }
            }
        }
        .navigationTitle("Ignored Hostnames")
    }

    private func deleteIgnoredHostnames(atOffsets offsets: IndexSet) {
        ignoredHostnames.remove(atOffsets: offsets)
    }
}

struct IgnoredHostnamesView_Previews: PreviewProvider {
    static var previews: some View {
        IgnoredHostnamesView()
    }
}