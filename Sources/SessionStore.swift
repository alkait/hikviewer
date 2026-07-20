// SessionStore.swift — persisted "pick up where you left off" state: which
// view was open (grid or a camera) and, per camera, live-vs-playback, the
// last playback position, and whether supplementary panes were showing.
// The pane set/layout itself lives in layouts.json (LayoutStore).

import Foundation

enum ViewMode: String, Codable { case live, playback }
enum AppLocation: String, Codable { case grid, camera }

struct CameraViewState: Codable {
    var mode: ViewMode
    /// Kept even in live mode — P resumes playback from here.
    var playbackPosition: Date?
    var panesVisible: Bool
}

struct SessionState: Codable {
    var location: AppLocation
    var cameraHost: String?
    var perCamera: [String: CameraViewState]
}

/// Same shape as LayoutStore: UI state, no credentials, not part of
/// export/import. Written eagerly on every transition, so a crash loses at
/// most the in-flight playback position.
enum SessionStore {
    static let fileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("hikviewer/state.json")
    }()

    private(set) static var state: SessionState = load()

    private static func load() -> SessionState {
        guard let data = try? Data(contentsOf: fileURL),
              let s = try? JSONDecoder().decode(SessionState.self, from: data) else {
            return SessionState(location: .grid, cameraHost: nil, perCamera: [:])
        }
        return s
    }

    static func update(_ mutate: (inout SessionState) -> Void) {
        mutate(&state)
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
