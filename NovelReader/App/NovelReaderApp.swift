import SwiftUI

@main
struct NovelReaderApp: App {
    @StateObject private var libraryStore = LibraryStore()
    @StateObject private var sourceStore = SourceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(libraryStore)
                .environmentObject(sourceStore)
                .onAppear {
                    sourceStore.addSampleSourceIfNeeded()
                }
        }
    }
}