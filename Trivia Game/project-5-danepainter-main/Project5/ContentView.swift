//
//  ContentView.swift
//  Project5
//
//  Created by Dane Shaw on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    // User input properties
    @State private var numberOfQuestions: Int = 10
    @State private var numberInput: String = "10"
    @State private var selectedCategory: String = "Any Category"
    @State private var selectedDifficulty: String = "easy"
    @State private var selectedType: String = "multiple choice"
    
    //results / loading/errors
    @State private var isLoading: Bool = false
    @State private var fetchError: String?
    @State private var questions: [TriviaQuestion] = []
    @State private var showingQuiz = false
    
    
    // Category options based on the image
    private let categories = [
        "Any Category",
        "General Knowledge",
        "Entertainment: Books",
        "Entertainment: Film",
        "Entertainment: Music",
        "Entertainment: Musicals & Theatres",
        "Entertainment: Television",
        "Entertainment: Video Games",
        "Entertainment: Board Games",
        "Science & Nature",
        "Science: Computers",
        "Science: Mathematics",
        "Mythology",
        "Sports",
        "Geography",
        "History",
        "Politics",
        "Art",
        "Celebrities",
        "Animals",
        "Vehicles",
        "Entertainment: Comics",
        "Science: Gadgets",
        "Entertainment: Japanese Anime & Manga",
        "Entertainment: Cartoon & Animations"
    ]
    
    private let difficulties = ["easy", "medium", "hard"]
    private let types = ["multiple choice", "true / false"]

    private func categoryID(for name: String) -> Int? {
    let map: [String: Int] = [
        "General Knowledge": 9,
        "Entertainment: Books": 10,
        "Entertainment: Film": 11,
        "Entertainment: Music": 12,
        "Entertainment: Musicals & Theatres": 13,
        "Entertainment: Television": 14,
        "Entertainment: Video Games": 15,
        "Entertainment: Board Games": 16,
        "Science & Nature": 17,
        "Science: Computers": 18,
        "Science: Mathematics": 19,
        "Mythology": 20,
        "Sports": 21,
        "Geography": 22,
        "History": 23,
        "Politics": 24,
        "Art": 25,
        "Celebrities": 26,
        "Animals": 27,
        "Vehicles": 28,
        "Entertainment: Comics": 29,
        "Science: Gadgets": 30,
        "Entertainment: Japanese Anime & Manga": 31,
        "Entertainment: Cartoon & Animations": 32
    ]
    return map[name]
}

private func apiType(for uiType: String) -> String? {
    switch uiType {
    case "multiple choice": return "multiple"
    case "true / false": return "boolean"
    default: return nil
    }
}
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Trivia Quiz Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 25) {
                    // Number of Questions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Questions")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                HStack(spacing: 12) {
                    // Numeric text input
                    TextField("1–50", text: $numberInput)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 70, height: 36)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .onChange(of: numberInput) { _, newValue in
                            // Keep only digits
                            let digits = newValue.filter { $0.isNumber }
                            if digits != newValue { numberInput = digits }
                            // Clamp to 1...50, reflect into the bound Int
                            if let value = Int(digits) {
                                let clamped = min(max(value, 1), 50)
                                if clamped != value { numberInput = String(clamped) }
                                numberOfQuestions = clamped
                            }
                        }

                    // Stepper stays in sync with the text field
                    Stepper(value: $numberOfQuestions, in: 1...50) {
                        Text("\(numberOfQuestions)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 40)
                    }
                    .labelsHidden()
                    .onChange(of: numberOfQuestions) { _, newValue in
                        if numberInput != String(newValue) {
                            numberInput = String(newValue)
                        }
                    }

                    Spacer()
                }
                                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Category Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Menu {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Text(category)
                                        if selectedCategory == category {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCategory)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Difficulty Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                Button(action: {
                                    selectedDifficulty = difficulty
                                }) {
                                    Text(difficulty.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedDifficulty == difficulty ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    // Type Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Type")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(types, id: \.self) { type in
                                Button(action: {
                                    selectedType = type
                                }) {
                                    Text(type.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedType == type ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedType == type ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Status indicators
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading questions...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                if let fetchError = fetchError {
                    Text(fetchError)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if !questions.isEmpty && !isLoading {
                    Text("Loaded \(questions.count) question(s).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Start Quiz Button
                Button(action: {
                    startQuiz()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingQuiz) {
            QuizView(questions: questions)
        }
    }
    
    private func startQuiz() {
        isLoading = true
        fetchError = nil
        questions = []

        let amount = numberOfQuestions
        let catID = selectedCategory == "Any Category" ? nil : categoryID(for: selectedCategory)
        let diff = selectedDifficulty // already "easy|medium|hard"
        let type = apiType(for: selectedType)

        Task {
            do {
                let fetched = try await OpenTriviaAPI.shared.fetchQuestions(
                    amount: amount,
                    categoryID: catID,
                    difficulty: diff,
                    type: type
                )
                await MainActor.run {
                    self.questions = fetched
                    self.isLoading = false
                    self.showingQuiz = true
                    print("Fetched \(fetched.count) questions.")
                }
            } catch {
                await MainActor.run {
                    self.fetchError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
                    self.isLoading = false
                    print("Error: \(self.fetchError!)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
