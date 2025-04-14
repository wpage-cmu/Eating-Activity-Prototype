//contentView
import ActivityKit
import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var activity: Activity<TimerAttributes>? = nil
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack(spacing: 24) {
            // Section 1: Microphone Control
            VStack(spacing: 12) {
                Text("Microphone")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(audioManager.isRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(audioManager.isRunning ? "Active" : "Inactive")
                        .foregroundColor(audioManager.isRunning ? .green : .red)
                }
                
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
                .buttonStyle(.bordered)
                .tint(audioManager.isRunning ? .red : .blue)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
            
            // Section 2: Sound Classification Results
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound Classification")
                    .font(.headline)
                
                if !audioManager.detectedSounds.isEmpty {
                    ForEach(audioManager.detectedSounds.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { sound, confidence in
                        HStack {
                            Text(formatSoundLabel(sound))
                                .frame(width: 120, alignment: .leading)
                            
                            ProgressView(value: confidence)
                                .progressViewStyle(.linear)
                            
                            Text("\(Int(confidence * 100))%")
                                .frame(width: 40, alignment: .trailing)
                                .monospacedDigit()
                        }
                    }
                } else if audioManager.isRunning {
                    Text("Listening for sounds...")
                        .foregroundColor(.secondary)
                } else {
                    Text("Start microphone to detect sounds")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
            
            // Section 3: Live Activity Control
            VStack(spacing: 12) {
                Text("Live Activity")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(activity != nil ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    
                    Text(activity != nil ? "Active" : "Inactive")
                        .foregroundColor(activity != nil ? .green : .gray)
                }
                
                HStack(spacing: 16) {
                    Button("Start Activity") {
                        startActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(activity != nil)
                    
                    Button("Stop Activity") {
                        stopActivity()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(activity == nil)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
        }
        .padding()
    }
    
    // Helper function to format sound label for display
    private func formatSoundLabel(_ label: String) -> String {
        // Convert snake_case to Title Case with spaces
        let words = label.split(separator: "_")
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
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
}
