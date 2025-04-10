//
//  AudioManagerModels.swift
//  Remaining Calories
//
//  Created by William Scott on 4/10/25.
//

import AVFoundation
import SoundAnalysis

class MicrophoneAudioClassifier {
    private let audioEngine = AVAudioEngine()
    private var soundClassifier: FoodPredictionModel_3_d_.model // Replace with your trained Core ML model
    private var resultsObserver: ResultsObserver?

    init(model: MLModel) {
        let config = MLModelConfiguration()
        do  {
            self.soundClassifier = try FoodPredictionModel_3_d_(configuration: config)
        } catch {
            //handle error
            print("Error in Loading Food Prediction Classifier: ", error)
        }
        //self.soundClassifier = FoodPredictionModel_3_d_()
        self.resultsObserver = ResultsObserver()
    }

    func startMicrophoneAnalysis(windowDuration: TimeInterval = 5.75, overlapFactor: Double = 0.1) {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let analyzer = SNAudioStreamAnalyzer(format: format)

        //guard self.soundClassifier.equal(FoodPredictionModel_3_d_) else {
        //    print("Sound classifier model is not loaded.")
        //    return
        //}

        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier)
            request.windowDuration = CMTimeMakeWithSeconds(windowDuration, preferredTimescale: Int32(format.sampleRate))
            request.overlapFactor = overlapFactor

            analyzer.add(request, withObserver: resultsObserver!)
        } catch {
            print("Error creating sound classification request: \(error.localizedDescription)")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }

        do {
            try audioEngine.start()
            print("Audio engine started.")
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func stopMicrophoneAnalysis() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        print("Audio engine stopped.")
    }
}

class ResultsObserver: NSObject, SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult,
              let topClassification = classificationResult.classifications.first else { return }

        let identifier = topClassification.identifier
        let confidence = topClassification.confidence * 100
        print("Detected sound: \(identifier) with confidence \(confidence)%")
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound analysis failed with error: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("Sound analysis completed.")
    }
}
