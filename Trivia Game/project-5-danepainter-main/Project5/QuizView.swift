//
//  QuizView.swift
//  Project5
//
//  Created by Dane Shaw on 10/29/25.
//

import SwiftUI

struct QuizView: View {
    let questions: [TriviaQuestion]
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String] = []
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    @State private var showingResults = false
    @State private var score = 0
    @State private var showingFeedback = false
    
    var currentQuestion: TriviaQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with timer
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                Text("Time remaining: \(timeRemaining)s")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Quiz content using List and Card
            if let question = currentQuestion {
                List {
                    Section {
                        Card {
                            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(question.question)
                                .font(.title2)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        if question.type == "boolean" {
                            ForEach(["True", "False"], id: \.self) { option in
                                let colors = colorsFor(option: option, in: question)
                                AnswerButton(
                                    text: option,
                                    isSelected: selectedAnswers.indices.contains(currentQuestionIndex) &&
                                               selectedAnswers[currentQuestionIndex] == option,
                                    backgroundColor: colors.background,
                                    borderColor: colors.border,
                                    action: {
                                        guard !showingFeedback else { return }
                                        selectAnswer(option)
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } else {
                            ForEach(Array(question.allAnswersShuffled.enumerated()), id: \.offset) { index, option in
                                let label = "\(Character(UnicodeScalar(65 + index)!)). \(option)"
                                let colors = colorsFor(option: option, in: question)
                                AnswerButton(
                                    text: label,
                                    isSelected: selectedAnswers.indices.contains(currentQuestionIndex) &&
                                               selectedAnswers[currentQuestionIndex] == option,
                                    backgroundColor: colors.background,
                                    borderColor: colors.border,
                                    action: {
                                        guard !showingFeedback else { return }
                                        selectAnswer(option)
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
            
            // Submit button
            Button(action: {
                if showingFeedback {
                    // Move on
                    if isLastQuestion {
                        calculateScore()
                        showingResults = true
                    } else {
                        showingFeedback = false
                        nextQuestion()
                    }
                } else {
                    // Reveal correctness
                    showingFeedback = true
                }
            }) {
                Text(showingFeedback ? (isLastQuestion ? "Submit" : "Next Question") : "Check Answer")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedAnswers.indices.contains(currentQuestionIndex) ? (showingFeedback ? Color.blue : Color.green) : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!selectedAnswers.indices.contains(currentQuestionIndex))
            .padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("Quiz Complete!", isPresented: $showingResults) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your score: \(score)/\(questions.count)")
        }
    }
    
    private func selectAnswer(_ answer: String) {
        if selectedAnswers.indices.contains(currentQuestionIndex) {
            selectedAnswers[currentQuestionIndex] = answer
        } else {
            selectedAnswers.append(answer)
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time's up - auto submit
                calculateScore()
                showingResults = true
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func calculateScore() {
        score = 0
        for (index, question) in questions.enumerated() {
            if index < selectedAnswers.count && selectedAnswers[index] == question.correct_answer {
                score += 1
            }
        }
    }

    // Compute colors for an option given current feedback state
    private func colorsFor(option: String, in question: TriviaQuestion) -> (background: Color, border: Color) {
        // Default states
        let isSelected = selectedAnswers.indices.contains(currentQuestionIndex) && selectedAnswers[currentQuestionIndex] == option
        if showingFeedback {
            if option == question.correct_answer {
                return (Color.green.opacity(0.18), Color.green)
            }
            if isSelected {
                return (Color.red.opacity(0.18), Color.red)
            }
            return (Color(.systemGray6), Color.clear)
        } else {
            if isSelected {
                return (Color.blue.opacity(0.10), Color.blue)
            }
            return (Color(.systemGray6), Color.clear)
        }
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let backgroundColor: Color
    let borderColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Lightweight card container used in List rows
struct Card<Content: View>: View {
    private let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

#Preview {
    // Create sample questions for preview
    let sampleQuestions: [TriviaQuestion] = {
        let json = """
        {
            "response_code": 0,
            "results": [
                {
                    "category": "General Knowledge",
                    "type": "boolean",
                    "difficulty": "easy",
                    "question": "The United States Department of Homeland Security was formed in response to the September 11th attacks.",
                    "correct_answer": "True",
                    "incorrect_answers": ["False"]
                },
                {
                    "category": "History",
                    "type": "boolean",
                    "difficulty": "medium",
                    "question": "The Spitfire originated from a racing plane.",
                    "correct_answer": "True",
                    "incorrect_answers": ["False"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try! JSONDecoder().decode(TriviaResponse.self, from: json)
        return response.results
    }()
    
    QuizView(questions: sampleQuestions)
}
