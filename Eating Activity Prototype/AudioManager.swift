//
//  AudioManager.swift
//  Remaining Calories
//
//  Created by Will Page on 4/7/25.
//
// AudioManager.swift
// AudioManager.swift
import AVFoundation
import SwiftUI
import SoundAnalysis
import CoreML

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
                // Update the UI with the latest results
                DispatchQueue.main.async {
                    self?.detectedSounds = results
                }
            }
            
            //Try to load Food Prediction Model
            do {
                let config = MLModelConfiguration()
                self.foodPredictionModel = try FoodPredictionModel_3_d_(configuration: config)
                // Use `model` for predictions
            } catch {
                print("Error loading Food Prediction Model: \(error)")
            }
        } catch {
            print("Error setting up sound classifier: \(error.localizedDescription)")
        }
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
        // Remove the classification request from the analyzer
        if let request = classificationRequest {
            streamAnalyzer?.remove(request)
        }
        
        // Clean up audio engine
        audioEngine?.inputNode.removeTap(onBus: inputBus)
        audioEngine?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        
        // Reset the analyzer
        streamAnalyzer = nil
        
        isRunning = false
        print("Audio engine stopped")
    }

    private func installAudioTap() {
        let bufferSize: UInt32 = 8192
        
        audioEngine?.inputNode.installTap(onBus: inputBus,
                                         bufferSize: bufferSize,
                                         format: inputFormat) { [weak self] buffer, time in
            // Process the audio buffer for sound classification
            self?.analysisQueue.async {
                self?.streamAnalyzer?.analyze(buffer,
                                              atAudioFramePosition: AVAudioFramePosition(time.audioTimeStamp.mSampleTime))
                
            // Add a Predictions for the Food Prediction model
                /*
            self.foodPredictionModel?.prediction(audioFiles = buffer,
                                                 overlapFactor = request.overlapFactor,
                                                 predictionTimeWindowSize = request.windowDuration)
            */
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
