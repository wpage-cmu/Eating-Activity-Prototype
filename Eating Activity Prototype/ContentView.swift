//contentView
import ActivityKit
import SwiftUI

struct ContentView: View {
    @StateObject private var audioClassifierManager = AudioClassifierManager()
    var body: some View {
        VStack(spacing: 20) {
            Text("Detected Sound:")
                .font(.headline)
            Text(audioClassifierManager.detectedSound)
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text(String(format: "Confidence: %.2f%%", audioClassifierManager.confidence))
                .font(.subheadline)
            HStack(spacing: 20) {
                Button(action: {
                    audioClassifierManager.startClassification()
                }) {
                    Text("Start Classification")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {
                    audioClassifierManager.stopClassification()
                }) {
                    Text("Stop Classification")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .navigationTitle("Sound Classifier")
    }
}

//#Preview {
//    ContentView()
//}

/*
struct ContentView: View {
    @State       private var activity: Activity<TimerAttributes>? = nil
    @StateObject private var audioClassifierManager = AudioClassifierManager()
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Start Activity") {
                startActivity()
            }
            Button("Stop Activity") {
                stopActivity()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
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
 */
