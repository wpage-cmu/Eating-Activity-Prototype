//Live_Activity.swift
import ActivityKit
import WidgetKit
import SwiftUI

struct TimerActivityView: View {
    let context: ActivityViewContext<TimerAttributes>
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "fork.knife")
                    Text(context.attributes.timerName)
                }
                    .font(.headline)
                    .frame(width:.infinity)
                
                Spacer()
                
                Text(context.state.startTime, style: .timer)
                    .font(.title3)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            }
            .frame(width:.infinity)
            .foregroundStyle(.cyan)
            
            HStack {
                Button(action: {
                }) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                
                Spacer().frame(width: 8)
                
                Button(action: {
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Log Food")
                            .bold()
                            .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .tint(.cyan)
        }
        .padding()
    }
}

struct Live_Activity: Widget {
    let kind: String = "Live_Activity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            TimerActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundColor(.cyan)
                        .padding(.leading, 4)

                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Use timer style for clean display
                    Text(context.state.startTime, style: .timer)
                        .monospacedDigit()
                        .foregroundColor(.cyan)
                        .frame(maxWidth: 40)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) { // Stack to group remaining cal and started time
                        HStack(spacing: 4) {
                            Text("Remaining:")
                                .foregroundColor(.cyan)
                            Text("650")
                                .foregroundColor(.white)
                            Text("cal")
                                .foregroundColor(.white)
                        }
                        .font(.headline)
                        
                        HStack(spacing: 0) {
                            Text("It's your ")
                            Text("4th time")
                                .foregroundColor(.white)
                            Text(" eating today.")
                        }
                            .font(.footnote .bold())
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(action: {
                        }) {
                            Text("Stop")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer().frame(width: 8)
                        
                        Button(action: {
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Log Food")
                                    .bold()
                                    .padding(.vertical, 4)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 4)
                    .tint(.cyan)
                }



            } compactLeading: {
                Image(systemName: "fork.knife")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                // Timer style for clean display
                Text(context.state.startTime, style: .timer)
                    .monospacedDigit()
                    .foregroundColor(.cyan)
                    .frame(maxWidth: 33)
            } minimal: {
                Image(systemName: "fork.knife")
                    .foregroundColor(.cyan)
            }
            .keylineTint(.cyan)
            .contentMargins(.horizontal, 10, for: .compactLeading)
            .contentMargins(.horizontal, 10, for: .compactTrailing)
        }
    }
}
