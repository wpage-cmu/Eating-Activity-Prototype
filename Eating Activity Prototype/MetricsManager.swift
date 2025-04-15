//
//  MetricsManager.swift
//  Remaining Calories
//
//  Created by Will Page on 4/14/25.
//
import Foundation
import Combine

enum DetectionOutcome {
    case truePositive(foodLogged: Bool, foodType: String?)
    case falsePositive
    case falseNegative
    case unknownOutcome
}

class MetricsManager: ObservableObject {
    // Notification metrics
    @Published var notificationsSent = 0
    @Published var truePositives = 0
    @Published var falsePositives = 0
    @Published var falseNegatives = 0
    
    // Food prediction metrics
    @Published var correctFoodPredictions = 0
    @Published var incorrectFoodPredictions = 0
    
    // Detailed metrics
    @Published var detectionByModality: [String: [DetectionOutcome]] = [:]
    @Published var detectionByModel: [String: [DetectionOutcome]] = [:]
    
    // Current settings
    private var currentModality: String = "Native"
    private var currentModel: String = "Native"
    
    // Track notification
    func trackNotificationSent() {
        notificationsSent += 1
    }
    
    // Track user response to notification
    func trackNotificationResponse(userLoggedFood: Bool, predictedFoodCorrect: Bool?, selectedFood: String?) {
        if userLoggedFood {
            // True positive - eating was detected and user confirmed by logging food
            truePositives += 1
            
            // Track if food prediction was correct (if applicable)
            if let predictedCorrect = predictedFoodCorrect {
                if predictedCorrect {
                    correctFoodPredictions += 1
                } else {
                    incorrectFoodPredictions += 1
                }
            }
            
            // Record detailed metrics
            let outcome = DetectionOutcome.truePositive(foodLogged: true, foodType: selectedFood)
            recordDetailedMetrics(outcome: outcome)
        } else {
            // False positive - eating was detected but user dismissed
            falsePositives += 1
            
            // Record detailed metrics
            let outcome = DetectionOutcome.falsePositive
            recordDetailedMetrics(outcome: outcome)
        }
    }
    
    // Track manual food log (eating wasn't detected)
    func trackManualFoodLog() {
        falseNegatives += 1
        
        // Record detailed metrics
        let outcome = DetectionOutcome.falseNegative
        recordDetailedMetrics(outcome: outcome)
    }
    
    // Update current settings
    func updateSettings(modality: String, model: String) {
        self.currentModality = modality
        self.currentModel = model
    }
    
    // Record detailed metrics
    private func recordDetailedMetrics(outcome: DetectionOutcome) {
        // Record by modality
        if detectionByModality[currentModality] == nil {
            detectionByModality[currentModality] = []
        }
        detectionByModality[currentModality]?.append(outcome)
        
        // Record by model
        if detectionByModel[currentModel] == nil {
            detectionByModel[currentModel] = []
        }
        detectionByModel[currentModel]?.append(outcome)
    }
    
    // Get accuracy metrics
    func getAccuracyMetrics() -> (overallAccuracy: Double, byModality: [String: Double], byModel: [String: Double]) {
        let overallTotal = Double(truePositives + falsePositives + falseNegatives)
        let overallAccuracy = overallTotal > 0 ? Double(truePositives) / overallTotal : 0
        
        var accuracyByModality: [String: Double] = [:]
        var accuracyByModel: [String: Double] = [:]
        
        // Calculate accuracy by modality
        for (modality, outcomes) in detectionByModality {
            let truePos = outcomes.filter { if case .truePositive(_, _) = $0 { return true } else { return false } }.count
            let total = outcomes.count
            accuracyByModality[modality] = total > 0 ? Double(truePos) / Double(total) : 0
        }
        
        // Calculate accuracy by model
        for (model, outcomes) in detectionByModel {
            let truePos = outcomes.filter { if case .truePositive(_, _) = $0 { return true } else { return false } }.count
            let total = outcomes.count
            accuracyByModel[model] = total > 0 ? Double(truePos) / Double(total) : 0
        }
        
        return (overallAccuracy, accuracyByModality, accuracyByModel)
    }
    
    // Export metrics as CSV
    func exportMetricsCSV() -> String {
        var csv = "Metric,Value\n"
        csv += "Notifications Sent,\(notificationsSent)\n"
        csv += "True Positives,\(truePositives)\n"
        csv += "False Positives,\(falsePositives)\n"
        csv += "False Negatives,\(falseNegatives)\n"
        csv += "Correct Food Predictions,\(correctFoodPredictions)\n"
        csv += "Incorrect Food Predictions,\(incorrectFoodPredictions)\n"
        
        // Add detailed metrics
        csv += "\nAccuracy by Modality\n"
        let (_, byModality, byModel) = getAccuracyMetrics()
        
        for (modality, accuracy) in byModality {
            csv += "\(modality),\(accuracy)\n"
        }
        
        csv += "\nAccuracy by Model\n"
        for (model, accuracy) in byModel {
            csv += "\(model),\(accuracy)\n"
        }
        
        return csv
    }
}
