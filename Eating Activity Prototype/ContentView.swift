//contentView
import ActivityKit
import SwiftUI

struct ContentView: View {
    @StateObject private var audioClassifierManager = AudioClassifierManager()
    @StateObject private var foodLogVM = FoodLogViewModel()
    @State private var predictedFood: String = ""
    @State private var showAddFood = false
    
    var body: some View {
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
                

           NavigationLink("Analytics", destination: AnalyticsView())
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
                
                Button("Submit") {
                    foodLogVM.saveFoodEntry(
                        predictedFood: predictedFood,
                        foodName: foodName,
                        calories: Int(calories),
                        wasPredictionCorrect: isPredictionConfirmed == true
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(foodName.isEmpty)
            }
        }
    }
}

struct AnalyticsView: View {
    // Assume you have arrays: actualLabels, predictedLabels
    @EnvironmentObject var foodLogVM: FoodLogViewModel
    
    var body: some View {
        VStack {
            List(foodLogVM.entries) { entry in
                VStack(alignment: .leading) {
                    Text("Predicted: \(entry.predictedFood)")
                    Text("Actual: \(entry.actualFood)")
                    Text("Calories: \(entry.calories)")
                    Text("Correct: \(entry.wasPredictionCorrect ? "Yes" : "No")")
                }
            }
        }
    }
}

//VStack {
    //Text("Confusion Matrix")
    // Display matrix in grid/table form

    //Text("Accuracy: \(accuracy)")
    //Text("Precision: \(precision)")
    //Text("Recall: \(recall)")
    // ... other metrics
