//contentView
import ActivityKit
import SwiftUI

struct ContentView: View {
    @StateObject private var audioClassifierManager = AudioClassifierManager()
    @StateObject private var foodLogVM = FoodLogViewModel()
    @State private var predictedFood: String = ""
    @State private var showAddFood = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Detected Sound:")
                    .font(.headline)
                Text(audioClassifierManager.detectedSound)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text(String(format: "Confidence: %.2f%%", audioClassifierManager.confidence))
                    .font(.subheadline)
                HStack(spacing: 20) {
                    Button(action: {
                        audioClassifierManager.startClassification()
                    }) {
                        Text("Start Classification")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button(action: {
                        audioClassifierManager.stopClassification()
                    }) {
                        Text("Stop Classification")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                Button("Log Food") {
                    // Trigger ML prediction and show form
                    predictedFood = audioClassifierManager.detectedSound
                    showAddFood = true
                }
                .sheet(isPresented: $showAddFood) {
                    AddFoodForm(predictedFood: $predictedFood)
                }
                
                NavigationLink("History", destination: EatingHistory())
                NavigationLink("Performance", destination: AnalyticsView())
            }
        }
        .padding()
        .navigationTitle("Sound Classifier")
        .environmentObject(foodLogVM)
    }
}

struct AddFoodForm: View {
    @Binding var predictedFood: String
    @State private var calories: Double = 0
    @State private var isPredictionConfirmed: Bool? = nil
    @State private var correctedFood: String = ""
    @State private var selectedDate = Date()
    @EnvironmentObject var foodLogVM: FoodLogViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var foodName: String {
            // Use correctedFood if user provided it, otherwise predictedFood
            isPredictionConfirmed == false && !correctedFood.isEmpty ? correctedFood : predictedFood
        }

    var body: some View {
        Form {
            Section(header: Text("Predicted Food")) {
                Text(predictedFood)
                    .font(.headline)
                    .padding(.vertical)
                
                Text("Is this prediction correct?")
                    .font(.subheadline)
                
                HStack {
                    Button(action: {
                        isPredictionConfirmed = true
                    }) {
                        Label("Yes", systemImage: isPredictionConfirmed == true ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        isPredictionConfirmed = false
                    }) {
                        Label("No", systemImage: isPredictionConfirmed == false ? "xmark.circle.fill" : "circle")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            if isPredictionConfirmed == false {
                Section(header: Text("Correct Food Name")) {
                    TextField("Enter correct food", text: $correctedFood)
                        .autocapitalization(.words)
                }
            }
            
            if isPredictionConfirmed != nil {
                Section(header: Text("Calories")) {
                    HStack {
                        Slider(value: $calories, in: 0...2000, step: 10)
                        Text("\(Int(calories)) kcal")
                    }
                }
               
                Section(header: Text("Date & Time")) {
                    DatePicker(
                        "When did you eat?",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Button("Submit") {
                    foodLogVM.saveFoodEntry(
                        predictedFood: predictedFood,
                        foodName: foodName,
                        calories: Int(calories),
                        wasPredictionCorrect: isPredictionConfirmed == true,
                        date: selectedDate
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(foodName.isEmpty)
            }
        }
    }
}

struct EatingHistory: View {
    // Assume you have arrays: actualLabels, predictedLabels
    @EnvironmentObject var foodLogVM: FoodLogViewModel
    
    var body: some View {
        List(foodLogVM.entries) { entry in
            VStack(alignment: .leading) {
                Text("Predicted: \(entry.predictedFood)")
                Text("Actual: \(entry.actualFood)")
                Text("Calories: \(entry.calories)")
                Text("Correct: \(entry.wasPredictionCorrect ? "Yes" : "No")")
                Text("Date & Time: \(entry.date)")
            }
        }
    }
}

struct AnalyticsView: View {
    @EnvironmentObject var foodLogVM: FoodLogViewModel

    var body: some View {
        let analytics = FoodPredictionAnalytics(entries: foodLogVM.entries)
        let labels   = analytics.labels
        let matrix   = analytics.confusionMatrix
        let metrics  = analytics.perClassMetrics()
        let accuracy = analytics.overallAccuracy()
        let macroF1  = analytics.macroAveragedF1()
        
        ScrollView {
            Text("Confusion Matrix").font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    Text("Actual \\ Predicted").frame(width: 120)
                    ForEach(labels, id: \.self) { label in
                        Text(label).bold().frame(minWidth: 80)
                    }
                }
                ForEach(0..<labels.count, id: \.self) { i in
                    HStack {
                        Text(labels[i]).bold().frame(width: 120)
                        ForEach(0..<labels.count, id: \.self) { j in
                            Text("\(matrix[i][j])")
                                .frame(minWidth: 80)
                                .background(i == j ? Color.green.opacity(0.2) : Color.red.opacity(0.1))
                        }
                    }
                }
            }
            Divider()
            Text("Overall Accuracy: \(String(format: "%.2f", accuracy * 100))%")
                .font(.title3)
                .padding(.vertical)
            Text("Macro F1 Score: \(String(format: "%.2f", macroF1))")
                .font(.title3)
            Divider()
            Text("Per-Class Metrics").font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    Text("Class").bold().frame(width: 80)
                    Text("Precision").bold().frame(width: 80)
                    Text("Recall").bold().frame(width: 80)
                    Text("F1-Score").bold().frame(width: 80)
                    Text("Support").bold().frame(width: 80)
                }
                ForEach(labels, id: \.self) { label in
                    let m = metrics[label] ?? FoodPredictionAnalytics.Metrics(precision: 0, recall: 0, f1: 0, support: 0)
                    HStack {
                        Text(label).frame(width: 80)
                        Text(String(format: "%.2f", m.precision)).frame(width: 80)
                        Text(String(format: "%.2f", m.recall)).frame(width: 80)
                        Text(String(format: "%.2f", m.f1)).frame(width: 80)
                        Text("\(m.support)").frame(width: 80)
                    }
                }
            }
        }
        .padding()
    }
}
