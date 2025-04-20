//
//  FoodPredictionAnalytics.swift
//  Remaining Calories
//
//  Created by William Scott on 4/20/25.
//

import Foundation

class FoodPredictionAnalytics {
    let entries: [FoodEntry]
    let labels: [String]
    let labelIndex: [String: Int]
    let confusionMatrix: [[Int]]
    
    //Labels from training data
    private var filteredLabels: [String] = ["pizza", "jelly", "wings", "chocolate", "grapes", "salmon", "burger", "gummies", "aloe", "fries", "chips", "noodles", "cabbage", "drinks", "carrots", "ice-cream", "soup", "pickles", "ribs", "candied_fruits"]
    private var constrained: Bool = false;
    
    init(entries: [FoodEntry], constraintType: Bool = false) {
        self.entries     = entries
        self.constrained = constraintType
        if constraintType {
            //Only use labels present in filteredLabels
            self.labels = filteredLabels
        } else {
            //Collect all unique labels (predicted and actual), sorted for consistency
            let allLabels = Set(entries.flatMap { [$0.predictedFood, $0.actualFood] })
            self.labels = Array(allLabels).sorted()
        }
        self.labelIndex = Dictionary(uniqueKeysWithValues: labels.enumerated().map { ($1, $0) })
        if constraintType {
            self.confusionMatrix = FoodPredictionAnalytics.buildConfusionMatrix(entries: entries, labels: labels, labelIndex: labelIndex)
        } else {
            self.confusionMatrix = FoodPredictionAnalytics.buildUnconstrainedConfusionMatrix(entries: entries, labels: labels, labelIndex: labelIndex)
        }
        
    }
    
    //Building Confusion Matrix
    static func buildConfusionMatrix(entries: [FoodEntry], labels: [String], labelIndex: [String: Int]) -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: labels.count), count: labels.count)
        //Only Compute for Labels within filteredLabelSet
        let labelSet = Set(labels)
        _ = entries.filter { labelSet.contains($0.actualFood) && labelSet.contains($0.predictedFood) }
        for entry in entries {
            if let actualIdx = labelIndex[entry.actualFood], let predIdx = labelIndex[entry.predictedFood] {
                matrix[actualIdx][predIdx] += 1
            }
        }
        return matrix
    }
    
    static func buildUnconstrainedConfusionMatrix(entries: [FoodEntry], labels: [String], labelIndex: [String: Int]) -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: labels.count), count: labels.count)
        for entry in entries {
            if let actualIdx = labelIndex[entry.actualFood], let predIdx = labelIndex[entry.predictedFood] {
                matrix[actualIdx][predIdx] += 1
            }
        }
        return matrix
    }
    
    //Building Metrics Struct
    struct Metrics {
        let precision: Double
        let recall: Double
        let f1: Double
        let support: Int
    }
    
    func perClassMetrics() -> [String: Metrics] {
        var result: [String: Metrics] = [:]
        let n = labels.count
        for i in 0..<n {
            let tp = confusionMatrix[i][i]
            let fp = (0..<n).map { confusionMatrix[$0][i] }.reduce(0, +) - tp
            let fn = (0..<n).map { confusionMatrix[i][$0] }.reduce(0, +) - tp
            let support = (0..<n).map { confusionMatrix[i][$0] }.reduce(0, +)
            let precision = tp + fp == 0 ? 0 : Double(tp) / Double(tp + fp)
            let recall = tp + fn == 0 ? 0 : Double(tp) / Double(tp + fn)
            let f1 = (precision + recall) == 0 ? 0 : 2 * precision * recall / (precision + recall)
            result[labels[i]] = Metrics(precision: precision, recall: recall, f1: f1, support: support)
        }
        return result
    }
    
    func overallAccuracy() -> Double {
        let n = labels.count
        let correct = (0..<n).map { confusionMatrix[$0][$0] }.reduce(0, +)
        let total = confusionMatrix.flatMap { $0 }.reduce(0, +)
        return total == 0 ? 0 : Double(correct) / Double(total)
    }
    
    func macroAveragedF1() -> Double {
        let metrics = perClassMetrics()
        let sum = metrics.values.map { $0.f1 }.reduce(0, +)
        return metrics.isEmpty ? 0 : sum / Double(metrics.count)
    }
}
