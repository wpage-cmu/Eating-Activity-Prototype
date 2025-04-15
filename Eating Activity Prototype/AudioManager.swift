//
//  AudioManager.swift
//  Remaining Calories
//
//  Created by Will Page on 4/7/25.
//
// AudioManager.swift - Updated implementation with debouncing
import AVFoundation
import SwiftUI
import SoundAnalysis
import CoreML
import ActivityKit

class AudioManager: NSObject, ObservableObject {
    // Audio engine components
    private var audioEngine: AVAudioEngine?
    private var inputBus: AVAudioNodeBus = 0
    private var inputFormat: AVAudioFormat?
    
    // Sound classification components
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var classificationRequest: SNClassifySoundRequest?
    private var resultsObserver: SoundClassifierObserver?
    private var foodPredictionModel: FoodPredictionModel_3_d_?
    private let analysisQueue = DispatchQueue(label: "com.eatingactivity.AnalysisQueue")
    
    // Published properties
    @Published var isRunning: Bool = false
    @Published var detectedSounds: [String: Float] = [:]
    @Published var isEating: Bool = false
    @Published var eatingConfidence: Float = 0.0
    @Published var predictedFoodType: String? = nil
    
    // Live Activity properties
    @Published var currentActivity: Activity<TimerAttributes>? = nil
    
    // Debouncing properties
    private var eatingSessionCooldown: TimeInterval = 900 // 15 minutes
    private var lastEatingDetection: Date? = nil
    
    // Eating detection configuration
    private let eatingThreshold: Float = 0.6
    private let eatingKeywords = ["chewing", "bite", "eating", "crunching"]
    
    override init() {
        super.init()
        setupSoundClassifier()
    }
    
    private func setupSoundClassifier() {
        do {
            // Create the classification request
            let request = try SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1)
            request.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 48000)
            request.overlapFactor = 0.5
            
            // Store the request
            self.classificationRequest = request
            
            // Create the results observer
            self.resultsObserver = SoundClassifierObserver()
            self.resultsObserver?.resultsHandler = { [weak self] results in
                DispatchQueue.main.async {
                    self?.detectedSounds = results
                    self?.checkForEatingActivity(in: results)
                }
            }
            
            // Load custom food prediction model (optional)
            do {
                let config = MLModelConfiguration()
                self.foodPredictionModel = try FoodPredictionModel_3_d_(configuration: config)
            } catch {
                print("Error loading Food Prediction Model: \(error)")
            }
        } catch {
            print("Error setting up sound classifier: \(error.localizedDescription)")
        }
    }
    
    private func checkForEatingActivity(in classifications: [String: Float]) {
        // Check if we already have an active Live Activity
        if currentActivity != nil {
            return
        }
        
        // Check cooldown period
        if let lastDetection = lastEatingDetection {
            let timeSinceLastDetection = Date().timeIntervalSince(lastDetection)
            if timeSinceLastDetection < eatingSessionCooldown {
                return
            }
        }
        
        // Analyze detected sounds for eating patterns
        let totalEatingConfidence = eatingKeywords.reduce(0) { sum, keyword in
            sum + (classifications.filter { $0.key.localizedCaseInsensitiveContains(keyword) }
                        .values.max() ?? 0)
        }
        
        // Normalize confidence value
        eatingConfidence = min(totalEatingConfidence, 1.0)
        
        // Update eating state
        let wasEating = isEating
        isEating = eatingConfidence > eatingThreshold
        
        // Try to detect the most likely food type
        if isEating, let topSound = classifications.max(by: { $0.value < $1.value }) {
            predictedFoodType = topSound.key
        }
        
        // Trigger Live Activity if state changes to eating
        if !wasEating && isEating {
            lastEatingDetection = Date()
            startEatingActivity()
        }
    }
    
    private func startEatingActivity() {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not supported")
            return
        }
        
        // Create Live Activity
        let attributes = TimerAttributes(timerName: "Eating Timer")
        let contentState = TimerAttributes.ContentState(startTime: Date())
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
            print("Started Live Activity with ID: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func endEatingActivity() {
        Task {
            // Use the .end to complete the activity
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    func resetEatingSessionCooldown() {
        lastEatingDetection = nil
    }
    
    func startAudioEngine() {
        // Create a new audio engine
        audioEngine = AVAudioEngine()
        
        // Get the native audio format of the engine's input bus
        inputBus = AVAudioNodeBus(0)
        inputFormat = audioEngine?.inputNode.inputFormat(forBus: inputBus)
        
        do {
            // Configure audio session for recording
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create a new stream analyzer with the input format
            if let format = inputFormat {
                streamAnalyzer = SNAudioStreamAnalyzer(format: format)
                
                // Add the classification request to the analyzer
                if let request = classificationRequest, let observer = resultsObserver {
                    try streamAnalyzer?.add(request, withObserver: observer)
                }
            }
            
            // Install audio tap for processing
            installAudioTap()
            
            // Start the stream of audio data
            try audioEngine?.start()
            isRunning = true
            
            print("Audio engine started successfully")
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        if let request = classificationRequest {
            streamAnalyzer?.remove(request)
        }
        
        audioEngine?.inputNode.removeTap(onBus: inputBus)
        audioEngine?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        
        streamAnalyzer = nil
        isRunning = false
        
        // Also end any active eating session
        endEatingActivity()
        
        print("Audio engine stopped")
    }
    
    private func installAudioTap() {
        let bufferSize: UInt32 = 8192
        
        audioEngine?.inputNode.installTap(onBus: inputBus,
                                          bufferSize: bufferSize,
                                          format: inputFormat) { [weak self] buffer, time in
            self?.analysisQueue.async {
                self?.streamAnalyzer?.analyze(buffer,
                                              atAudioFramePosition: AVAudioFramePosition(time.audioTimeStamp.mSampleTime))
            }
        }
    }
}

// Observer that receives sound classification results
class SoundClassifierObserver: NSObject, SNResultsObserving {
    // Callback to pass results back to the AudioManager
    var resultsHandler: (([String: Float]) -> Void)?
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        // Handle sound classification results
        guard let result = result as? SNClassificationResult else { return }
        
        // Process and report the top classifications
        var classifications: [String: Float] = [:]
        
        for classification in result.classifications {
            // Only include results with reasonable confidence (above 0.1 or 10%)
            if classification.confidence > 0.1 {
                classifications[classification.identifier] = Float(classification.confidence)
            }
        }
        
        // Return the results through the callback
        resultsHandler?(classifications)
        
        // Log the top classification for debugging
        if let topClassification = result.classifications.first {
            print("Top sound: \(topClassification.identifier) - \(topClassification.confidence)")
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound classification error: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("Sound classification request completed")
    }
}
