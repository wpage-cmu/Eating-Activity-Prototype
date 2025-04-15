// ContentView.swift - Updated with debugging UI

import ActivityKit
import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                PrototypingView()
                    .navigationTitle("Prototyping")
                    .navigationBarTitleDisplayMode(.large)
                    .background(Color(.systemGroupedBackground))
            }
            .tabItem {
                Label("Prototyping", systemImage: "pencil.and.ruler.fill")
            }

            NavigationView {
                PreferencesView()
                    .navigationTitle("Preferences")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Preferences", systemImage: "gear")
            }
            
            NavigationView {
                AnalyticsView()
                    .navigationTitle("Analytics")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }
            
            // Add Debug Tab
            NavigationView {
                DebugView()
                    .navigationTitle("Debug")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Debug", systemImage: "hammer")
            }
        }
        .environmentObject(AudioManager())
        .environmentObject(MetricsManager())
    }
}

// New Debug View for testing
struct DebugView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        List {
            Section(header: Text("AUDIO STATUS")) {
                HStack {
                    Text("Recording Active")
                    Spacer()
                    Text(audioManager.isRunning ? "Yes" : "No")
                        .foregroundColor(audioManager.isRunning ? .green : .red)
                }
                
                HStack {
                    Text("Eating Detected")
                    Spacer()
                    Text(audioManager.isEating ? "Yes" : "No")
                        .foregroundColor(audioManager.isEating ? .green : .red)
                }
                
                HStack {
                    Text("Confidence Level")
                    Spacer()
                    Text(String(format: "%.1f%%", audioManager.eatingConfidence * 100))
                }
                
                if let foodType = audioManager.predictedFoodType {
                    HStack {
                        Text("Predicted Food")
                        Spacer()
                        Text(foodType)
                    }
                }
            }
            
            Section(header: Text("DETECTED SOUNDS")) {
                if audioManager.detectedSounds.isEmpty {
                    Text("No sounds detected yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(audioManager.detectedSounds.keys.sorted()), id: \.self) { sound in
                        if let confidence = audioManager.detectedSounds[sound] {
                            HStack {
                                Text(sound)
                                Spacer()
                                Text(String(format: "%.1f%%", confidence * 100))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("TEST CONTROLS")) {
                Button("Force Trigger Notification") {
                    // Force trigger eating notification for testing
                    withAnimation {
                        audioManager.isEating = true
                    }
                }
                .foregroundColor(.blue)
                
                Button("Reset Cooldown") {
                    audioManager.resetEatingSessionCooldown()
                }
                .foregroundColor(.blue)
                
                Button("End Current Activity") {
                    audioManager.endEatingActivity()
                }
                .foregroundColor(.red)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct PrototypingView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var metricsManager: MetricsManager
    
    @State private var stepperValue = 0
    @State private var isShowingLogFoodSheet = false
    @State private var isShowingFoodTypeSheet = false
    @State private var selectedFood: String? = nil
    @State private var manualLogMode: Bool = false
    @State private var debugText: String = "No events yet"
    
    // Store cancellables
    @State private var cancellables = Set<AnyCancellable>()
    
    let foodOptions = [
        "Lettuce",
        "Food Type 2",
        "Food Type 3",
        "Food Type 4",
        "Food Type 5",
        "Food Type 6",
        "Food Type 7",
        "Food Type 8",
        "Food Type 9",
        "Not Here"
    ]

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                // Top Section
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(stepperValue)")
                            .font(.largeTitle)
                            .bold()
                        Text("False Negatives")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        // Share action
                        shareAnalytics()
                    } label: {
                        Label("Share Analytics", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .cornerRadius(100)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Stepper("Eating not detected", value: $stepperValue)
                        .onChange(of: stepperValue) { oldValue, newValue in
                            if newValue > oldValue {
                                // Only track when the value increases
                                metricsManager.trackManualFoodLog()
                            }
                        }
                        .frame(height: 30)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                    Text("This app does not store audio recordings used for eating detection.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 5)
                }
            }

            Spacer()

            // Debug text area
            Text(debugText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

            // Status indicator when listening
            if audioManager.isRunning {
                VStack {
                    Text("Listening for eating sounds...")
                        .foregroundColor(.secondary)
                    
                    if audioManager.isEating {
                        Text("Eating detected!")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.top, 5)
                    }
                    
                    // Show confidence level
                    Text("Confidence: \(String(format: "%.1f%%", audioManager.eatingConfidence * 100))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            // Bottom Section
            VStack(spacing: 16) {
                HStack(spacing: 11) {
                    Button {
                        audioManager.startAudioEngine()
                        setupEatingDetection()
                        debugText = "Started listening at \(formattedTime())"
                    } label: {
                        Label("Start Listening", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(audioManager.isRunning)

                    Button {
                        audioManager.stopAudioEngine()
                        debugText = "Stopped listening at \(formattedTime())"
                    } label: {
                        Text("Stop Listening")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!audioManager.isRunning)
                }

                Button {
                    manualLogMode = true
                    isShowingLogFoodSheet = true
                    debugText = "Manual food log at \(formattedTime())"
                    
                    // If not in an eating session, it's a false negative
                    if !audioManager.isEating {
                        metricsManager.trackManualFoodLog()
                    }
                } label: {
                    Text("Log Food")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
            }
        }
        .padding()
        .onAppear {
            setupEatingDetection()
            
            // Check audio permission status
            checkAudioPermission()
        }

        // MARK: - Modals
        .sheet(isPresented: $isShowingLogFoodSheet) {
            NavigationStack {
                VStack(spacing: 0) {
                    List {
                        Section(
                            header: Text("FOOD LIST"),
                            footer: Text("If your food type is not listed, record what you ate in the notes app.")
                        ) {
                            ForEach(foodOptions, id: \.self) { option in
                                HStack {
                                    Text(option)
                                    Spacer()
                                    if option == selectedFood {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedFood = option
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)

                    // Large Done button at bottom
                    Button {
                        isShowingLogFoodSheet = false
                        
                        // Log food selection and end activity if not manual mode
                        if !manualLogMode {
                            // This was triggered by eating detection - track as true positive
                            metricsManager.trackNotificationResponse(
                                userLoggedFood: true,
                                predictedFoodCorrect: false,  // We don't know if prediction was correct
                                selectedFood: selectedFood
                            )
                            
                            // End the activity
                            audioManager.endEatingActivity()
                            
                            debugText = "Food logged: \(selectedFood ?? "unknown") at \(formattedTime())"
                        } else {
                            debugText = "Manual food logged: \(selectedFood ?? "unknown") at \(formattedTime())"
                        }
                        
                        // Reset manual mode flag
                        manualLogMode = false
                        
                        // Reset selected food
                        selectedFood = nil
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Log Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            isShowingLogFoodSheet = false
                            
                            // If canceled and not manual, log as false positive
                            if !manualLogMode {
                                metricsManager.trackNotificationResponse(
                                    userLoggedFood: false,
                                    predictedFoodCorrect: nil,
                                    selectedFood: nil
                                )
                                
                                // End the activity
                                audioManager.endEatingActivity()
                                
                                debugText = "Food detection canceled at \(formattedTime())"
                            } else {
                                debugText = "Manual food log canceled at \(formattedTime())"
                            }
                            
                            // Reset manual mode flag
                            manualLogMode = false
                            
                            // Reset selected food
                            selectedFood = nil
                        }
                    }
                }
            }
        }

        .sheet(isPresented: $isShowingFoodTypeSheet) {
            NavigationStack {
                VStack {
                    VStack(spacing: 16) {
                        Text("Sounds like you're eating...")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text(audioManager.predictedFoodType ?? "Food")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 100)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    
                    HStack(spacing: 11) {
                        Button {
                            // Food prediction was wrong
                            isShowingFoodTypeSheet = false
                            isShowingLogFoodSheet = true
                            
                            debugText = "Food prediction rejected at \(formattedTime())"
                            
                            // No need to track here, will track when food is logged
                        } label: {
                            Text("No")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button {
                            // Food prediction was correct
                            isShowingFoodTypeSheet = false
                            
                            // Log as true positive with correct prediction
                            metricsManager.trackNotificationResponse(
                                userLoggedFood: true,
                                predictedFoodCorrect: true,
                                selectedFood: audioManager.predictedFoodType
                            )
                            
                            debugText = "Food prediction confirmed: \(audioManager.predictedFoodType ?? "unknown") at \(formattedTime())"
                            
                            // End the activity
                            audioManager.endEatingActivity()
                        } label: {
                            Text("Yes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .navigationTitle("Food Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingFoodTypeSheet = false
                            
                            // Log as false positive
                            metricsManager.trackNotificationResponse(
                                userLoggedFood: false,
                                predictedFoodCorrect: nil,
                                selectedFood: nil
                            )
                            
                            debugText = "Food type prediction canceled at \(formattedTime())"
                            
                            // End the activity
                            audioManager.endEatingActivity()
                        }
                    }
                }
            }
        }
    }
    
    private func setupEatingDetection() {
        // Subscribe to eating state changes
        audioManager.$isEating
            .dropFirst() // Skip the initial value
            .sink { isEating in
                if isEating {
                    // New eating session detected
                    self.metricsManager.trackNotificationSent()
                    
                    debugText = "Eating detected at \(formattedTime()) with confidence: \(String(format: "%.1f%%", self.audioManager.eatingConfidence * 100))"
                    
                    if self.audioManager.predictedFoodType != nil {
                        // If we have a predicted food type, show that sheet
                        self.isShowingFoodTypeSheet = true
                    } else {
                        // Otherwise show the general food logging sheet
                        self.isShowingLogFoodSheet = true
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAudioPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            debugText = "Microphone permission granted"
        case .denied:
            debugText = "ERROR: Microphone permission denied"
        case .undetermined:
            debugText = "Microphone permission not determined yet"
        @unknown default:
            debugText = "Unknown microphone permission status"
        }
    }
    
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func shareAnalytics() {
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

// Update PreferencesView to connect with MetricsManager
struct PreferencesView: View {
    enum LiveActivityDesign: String, CaseIterable, Identifiable {
        case simple = "Simple"
        case foodType = "Food Type"
        var id: String { self.rawValue }
    }
    
    enum DetectionModel: String, CaseIterable, Identifiable {
        case native = "Native"
        case outside = "Outside"
        var id: String { self.rawValue }
    }
    
    @EnvironmentObject var metricsManager: MetricsManager
    @State private var selectedDesign: LiveActivityDesign = .simple
    @State private var selectedModel: DetectionModel = .native
    @AppStorage("eatingSessionCooldown") private var eatingSessionCooldown: Double = 900 // Default 15 min
    
    var body: some View {
        List {
            Section(
                header: Text("LIVE ACTIVITY DESIGN"),
                footer: Text("Live activities appear only when listening is turned on.")
            ) {
                ForEach(LiveActivityDesign.allCases) { design in
                    HStack {
                        Text(design.rawValue)
                        Spacer()
                        if design == selectedDesign {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDesign = design
                    }
                }
            }
            
            Section(header: Text("EATING DETECTION MODEL")) {
                ForEach(DetectionModel.allCases) { model in
                    HStack {
                        Text(model.rawValue)
                        Spacer()
                        if model == selectedModel {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedModel = model
                    }
                }
            }
            
            Section(header: Text("DETECTION SETTINGS")) {
                Stepper(value: $eatingSessionCooldown, in: 30...3600, step: 30) {
                    HStack {
                        Text("Cooldown period")
                        Spacer()
                        Text(formatSeconds(eatingSessionCooldown))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if remainingSeconds == 0 {
            return "\(minutes) min"
        } else {
            return "\(minutes) min \(remainingSeconds) sec"
        }
    }
}
