//
//  Eating_Activity_PrototypeApp.swift
//  Eating Activity Prototype
//
//  Created by Chance Castaneda on 3/11/25.
// In your Eating_Activity_PrototypeApp.swift
import SwiftUI
import AVFoundation

@main
struct Eating_Activity_PrototypeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(MetricsManager())
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                // Ensure audio continues in background
                setupBackgroundTask()
            case .active:
                // App is in foreground
                print("App moved to foreground")
            default:
                break
            }
        }
    }
    
    func setupBackgroundTask() {
        // Configure audio session for background
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated for background use")
        } catch {
            print("Failed to activate audio session in background: \(error)")
        }
    }
}
