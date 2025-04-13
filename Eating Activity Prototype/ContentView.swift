//contentView
import ActivityKit
import SwiftUI
import AVFoundation

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
        }
    }
}

#Preview {
    ContentView()
}

//Page Views

struct PrototypingView: View {
    @State private var stepperValue = 0
    @State private var isShowingLogFoodSheet = false
    @State private var isShowingFoodTypeSheet = false
    @State private var selectedFood: String? = nil

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
                    } label: {
                        Label("Share Analytics", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .cornerRadius(100)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Stepper("Eating not detected", value: $stepperValue)
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

            // Bottom Section
            VStack(spacing: 16) {
                HStack(spacing: 11) {
                    Button {
                        // Start Listening
                    } label: {
                        Label("Start Listening", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        // Stop Listening
                    } label: {
                        Text("Stop Listening")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    isShowingLogFoodSheet = true
                } label: {
                    Text("Log Food")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)

                Button {
                    isShowingFoodTypeSheet = true
                } label: {
                    Text("Food Type, delete this button later")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
            }
        }
        .padding()

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
                        }
                    }
                }
            }
        }


        .sheet(isPresented: $isShowingFoodTypeSheet) {
            NavigationStack {
                VStack {
                    VStack(spacing: 16) {
                        Text("Sounds like you’re eating...")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text("Lettuce")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 100)
                    }
                    .frame(width: .infinity, height: 500)
                    
                    HStack(spacing: 11) {
                        Button {
                            isShowingLogFoodSheet = true
                            isShowingFoodTypeSheet = false
                        } label: {
                            Text("No")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.accentColor)
                        
                        Button {
                            isShowingLogFoodSheet = true
                            isShowingFoodTypeSheet = false
                        } label: {
                            Text("Yes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.accentColor)
                    }
                }
                .padding()
                .navigationTitle("Food Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingFoodTypeSheet = false
                        }
                    }
                }
            }
        }
    }
}


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

    @State private var selectedDesign: LiveActivityDesign = .simple
    @State private var selectedModel: DetectionModel = .native

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
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}
