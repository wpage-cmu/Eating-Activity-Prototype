//
//  AnalyticsView.swift.swift
//  Remaining Calories
//
//  Created by Will Page on 4/14/25.
// AnalyticsView.swift - New file for displaying metrics
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var metricsManager: MetricsManager
    
    var body: some View {
        List {
            Section(header: Text("DETECTION METRICS")) {
                MetricRow(title: "Notifications Sent", value: metricsManager.notificationsSent)
                MetricRow(title: "True Positives", value: metricsManager.truePositives)
                MetricRow(title: "False Positives", value: metricsManager.falsePositives)
                MetricRow(title: "False Negatives", value: metricsManager.falseNegatives)
            }
            
            Section(header: Text("FOOD PREDICTION")) {
                MetricRow(title: "Correct Predictions", value: metricsManager.correctFoodPredictions)
                MetricRow(title: "Incorrect Predictions", value: metricsManager.incorrectFoodPredictions)
                
                if metricsManager.correctFoodPredictions + metricsManager.incorrectFoodPredictions > 0 {
                    let accuracy = Double(metricsManager.correctFoodPredictions) /
                                  Double(metricsManager.correctFoodPredictions + metricsManager.incorrectFoodPredictions)
                    MetricRow(title: "Prediction Accuracy", value: String(format: "%.1f%%", accuracy * 100))
                }
            }
            
            Section(header: Text("ACCURACY")) {
                let metrics = metricsManager.getAccuracyMetrics()
                MetricRow(title: "Overall Accuracy", value: String(format: "%.1f%%", metrics.overallAccuracy * 100))
                
                ForEach(Array(metrics.byModality.keys.sorted()), id: \.self) { modality in
                    if let accuracy = metrics.byModality[modality] {
                        MetricRow(title: "\(modality) Modality", value: String(format: "%.1f%%", accuracy * 100))
                    }
                }
                
                ForEach(Array(metrics.byModel.keys.sorted()), id: \.self) { model in
                    if let accuracy = metrics.byModel[model] {
                        MetricRow(title: "\(model) Model", value: String(format: "%.1f%%", accuracy * 100))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportMetrics) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func exportMetrics() {
        let csv = metricsManager.exportMetricsCSV()
        
        // Create a temporary file URL
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("eating_metrics.csv")
        
        // Write CSV to file
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Show share sheet
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            // Find the UIWindow to present from
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting metrics: \(error)")
        }
    }
}

struct MetricRow: View {
    var title: String
    var value: Any
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .foregroundColor(.secondary)
        }
    }
}
