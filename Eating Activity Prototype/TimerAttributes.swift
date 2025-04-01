//TimerAttributes.swift
import ActivityKit
import SwiftUI

struct TimerAttributes: ActivityAttributes {
    public typealias TimerStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var startTime: Date
    }
    
    var timerName: String
}
