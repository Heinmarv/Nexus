import SwiftUI
import Speech

@main
struct Nexus: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Kein WindowGroup notwendig, da wir keine UI in einem Fenster anzeigen
        Settings {
            Text("Einstellungen werden hier angezeigt.") // Beispiel für Einstellungen, optional
        }
    }
}
