//
//  Live_ActivityLiveActivity.swift
//  Live Activity
//
//  Created by Chance Castaneda on 3/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Live_ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Live_ActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Live_ActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Live_ActivityAttributes {
    fileprivate static var preview: Live_ActivityAttributes {
        Live_ActivityAttributes(name: "World")
    }
}

extension Live_ActivityAttributes.ContentState {
    fileprivate static var smiley: Live_ActivityAttributes.ContentState {
        Live_ActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Live_ActivityAttributes.ContentState {
         Live_ActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Live_ActivityAttributes.preview) {
   Live_ActivityLiveActivity()
} contentStates: {
    Live_ActivityAttributes.ContentState.smiley
    Live_ActivityAttributes.ContentState.starEyes
}
