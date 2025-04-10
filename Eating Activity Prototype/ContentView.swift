//contentView
import ActivityKit
import SwiftUI

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

//#Preview {
//    ContentView()
//}
