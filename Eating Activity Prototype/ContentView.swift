//contentView
import ActivityKit
import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var activity: Activity<TimerAttributes>? = nil
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Audio Engine status
            HStack {
                Image(systemName: audioManager.isRunning ? "mic.fill" : "mic.slash.fill")
                    .foregroundColor(audioManager.isRunning ? .green : .red)
                Text(audioManager.isRunning ? "Microphone Active" : "Microphone Inactive")
                    .foregroundColor(audioManager.isRunning ? .green : .red)
            }
            .font(.headline)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
            
            // Audio control buttons
            Button(audioManager.isRunning ? "Stop Microphone" : "Start Microphone") {
                if audioManager.isRunning {
                    audioManager.stopAudioEngine()
                } else {
                    requestMicrophonePermission { granted in
                        if granted {
                            audioManager.startAudioEngine()
                        } else {
                            print("Microphone permission denied")
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(audioManager.isRunning ? .red : .blue)
            .controlSize(.large)
            
            Text("Check the debug console to verify audio input")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Original Live Activity controls
            Button("Start Activity") {
                startActivity()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Stop Activity") {
                stopActivity()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func startActivity() {
        let attributes = TimerAttributes(timerName: "Eating Session")
        let state = TimerAttributes.TimerStatus(startTime: Date())
        
        activity = try? Activity<TimerAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
    }

    func stopActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
        }
    }

    func updateActivity() {
        let state = TimerAttributes.TimerStatus(startTime: Date())
        
        Task {
            await activity?.update(using: state)
        }
    }
}
