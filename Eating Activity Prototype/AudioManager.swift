//
//  AudioManager.swift
//  Remaining Calories
//
//  Created by Will Page on 4/7/25.
//
import AVFoundation
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    // Audio engine components
    private var audioEngine: AVAudioEngine?
    private var inputBus: AVAudioNodeBus = 0
    private var inputFormat: AVAudioFormat?
    
    // Published properties to observe in the UI
    @Published var isRunning: Bool = false
    
    override init() {
        super.init()
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
            
            // Simple verification tap that just logs
            installSimpleAudioTap()
            
            // Start the stream of audio data
            try audioEngine?.start()
            isRunning = true
            
            print("Audio engine started successfully")
            print("Audio format: \(inputFormat?.description ?? "unknown")")
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        audioEngine?.inputNode.removeTap(onBus: inputBus)
        audioEngine?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isRunning = false
        
        print("Audio engine stopped")
    }
    
    private func installSimpleAudioTap() {
        let bufferSize: UInt32 = 4096
        
        audioEngine?.inputNode.installTap(onBus: inputBus,
                                         bufferSize: bufferSize,
                                         format: inputFormat) { [weak self] buffer, time in
            // Just verify we're receiving data
            if let pcmBuffer = buffer as? AVAudioPCMBuffer {
                print("Received audio buffer with \(pcmBuffer.frameLength) frames at time: \(time.sampleTime)")
            }
        }
    }
}
