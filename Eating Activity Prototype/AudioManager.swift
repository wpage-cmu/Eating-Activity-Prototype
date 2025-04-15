//
//  AudioManager.swift
//  Remaining Calories
//
//  Created by Will Page on 4/7/25.
//
// AudioManager.swift - Updated implementation with debugging

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
    private var foodPredictionModel: MLModel? // Changed to generic MLModel
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
    private var eatingSessionCooldown: TimeInterval = 30 // REDUCED TO 30 SECONDS FOR TESTING
    private var lastEatingDetection: Date? = nil
    
    // Eating detection configuration - REDUCED THRESHOLD FOR TESTING
    private let eatingThreshold: Float = 0.2 // LOWERED FROM 0.6
    private let eatingKeywords = ["chewing", "bite", "eating", "crunching", "munching", "food"]
    
    // In AudioManager.swift - add to init()
    override init() {
        super.init()
        print("AudioManager initialized")
        setupSoundClassifier()
        
        // Register for audio session notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, audio has stopped
            print("Audio session interrupted - recording paused")
            
        case .ended:
            // Interruption ended, resume if needed
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // Resume audio session
                print("Audio session interruption ended - resuming")
                do {
                    try audioEngine?.start()
                    isRunning = true
                } catch {
                    print("Error resuming audio engine: \(error)")
                }
            }
            
        @unknown default:
            break
        }
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
            // Note: Commenting out specific model reference that might cause crashes
            /*
            do {
                let config = MLModelConfiguration()
                self.foodPredictionModel = try FoodPredictionModel_3_d_(configuration: config)
            } catch {
                print("Error loading Food Prediction Model: \(error)")
            }
            */
            
            print("Sound classifier setup completed successfully")
        } catch {
            print("ERROR setting up sound classifier: \(error.localizedDescription)")
        }
    }
    
    private func checkForEatingActivity(in classifications: [String: Float]) {
        print("Detected sounds: \(classifications)")
        
        // Check if we already have an active Live Activity
        if currentActivity != nil {
            print("Live Activity already active - ignoring new detection")
            return
        }
        
        // Check cooldown period
        if let lastDetection = lastEatingDetection {
            let timeSinceLastDetection = Date().timeIntervalSince(lastDetection)
            if timeSinceLastDetection < eatingSessionCooldown {
                print("In cooldown period - \(eatingSessionCooldown - timeSinceLastDetection) seconds remaining")
                return
            }
        }
        
        // Analyze detected sounds for eating patterns
        var totalEatingConfidence: Float = 0.0
        var matchedKeywords: [String] = []
        
        for keyword in eatingKeywords {
            let matchingClassifications = classifications.filter {
                $0.key.localizedCaseInsensitiveContains(keyword)
            }
            
            if let highestConfidence = matchingClassifications.values.max() {
                totalEatingConfidence += highestConfidence
                matchedKeywords.append(keyword)
            }
        }
        
        // Debug output
        if !matchedKeywords.isEmpty {
            print("MATCHED KEYWORDS: \(matchedKeywords)")
            print("Total eating confidence: \(totalEatingConfidence)")
        }
        
        // Normalize confidence value
        eatingConfidence = min(totalEatingConfidence, 1.0)
        print("Eating confidence: \(eatingConfidence)")
        
        // Update eating state
        let wasEating = isEating
        isEating = eatingConfidence > eatingThreshold
        
        // Try to detect the most likely food type
        if isEating, let topSound = classifications.max(by: { $0.value < $1.value }) {
            predictedFoodType = topSound.key
            print("Predicted food type: \(topSound.key)")
        }
        
        // Trigger Live Activity if state changes to eating
        if !wasEating && isEating {
            print("EATING DETECTED! Starting Live Activity...")
            lastEatingDetection = Date()
            startEatingActivity()
        }
    }
    
    private func startEatingActivity() {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ERROR: Live Activities not supported")
            return
        }
        
        // Create Live Activity
        let attributes = TimerAttributes(timerName: "Eating Timer")
        let contentState = TimerAttributes.ContentState(startTime: Date())
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: .token // Request push token for background updates
            )
            currentActivity = activity
            print("SUCCESS: Started Live Activity with ID: \(activity.id)")
            
            if let token = activity.pushToken {
                // You could store this token to send push updates
                // This allows updating the Live Activity via push notifications
                let tokenString = token.map { String(format: "%02x", $0) }.joined()
                print("Push token: \(tokenString)")
            }
        } catch {
            print("ERROR: Failed to start Live Activity: \(error)")
        }
    }
    
    func endEatingActivity() {
        Task {
            // Use the .end to complete the activity
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("Live Activity ended")
        }
    }
    
    func resetEatingSessionCooldown() {
        lastEatingDetection = nil
        print("Eating session cooldown reset")
    }
    
    // In AudioManager.swift
    func startAudioEngine() {
        print("Starting audio engine...")
        
        // Create a new audio engine
        audioEngine = AVAudioEngine()
        
        // Get the native audio format of the engine's input bus
        inputBus = AVAudioNodeBus(0)
        inputFormat = audioEngine?.inputNode.inputFormat(forBus: inputBus)
        
        do {
            // Configure audio session for recording with background capability
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                        mode: .default,
                                        options: [.mixWithOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create a new stream analyzer with the input format
            if let format = inputFormat {
                streamAnalyzer = SNAudioStreamAnalyzer(format: format)
                
                // Add the classification request to the analyzer
                if let request = classificationRequest, let observer = resultsObserver {
                    try streamAnalyzer?.add(request, withObserver: observer)
                    print("Added classification request to stream analyzer")
                }
            }
            
            // Install audio tap for processing
            installAudioTap()
            
            // Start the stream of audio data
            try audioEngine?.start()
            isRunning = true
            
            print("SUCCESS: Audio engine started successfully")
        } catch {
            print("ERROR: Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        print("Stopping audio engine...")
        
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
        
        print("Audio tap installed")
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
            // Lower threshold to 0.05 (5%) to catch more sounds
            if classification.confidence > 0.05 {
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
        print("ERROR: Sound classification error: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("Sound classification request completed")
    }
}
