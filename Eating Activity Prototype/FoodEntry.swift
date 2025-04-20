//
//  FoodEntry.swift
//  Remaining Calories
//
//  Created by William Scott on 4/20/25.
//

import Foundation
import SwiftUI

struct FoodEntry: Identifiable {
    let id = UUID()
    let foodName: String
    let calories: Int
    let wasPredictionCorrect: Bool
    let predictedFood: String
    let actualFood: String
    let date: Date
}

class FoodLogViewModel: ObservableObject {
    @Published var entries: [FoodEntry] = []
    
    func saveFoodEntry(predictedFood: String, foodName: String, calories: Int, wasPredictionCorrect: Bool, date: Date) {
        let entry = FoodEntry(
            foodName: foodName,
            calories: calories,
            wasPredictionCorrect: wasPredictionCorrect,
            predictedFood: predictedFood,
            actualFood: foodName,
            date: date
        )
        entries.append(entry)
    }
}

