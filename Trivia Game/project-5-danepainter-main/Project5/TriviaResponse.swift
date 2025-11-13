//
//  TriviaResponse.swift
//  Project5
//
//  Created by Dane Shaw on 10/29/25.
//

import Foundation

struct TriviaResponse: Decodable {
    let response_code: Int
    let results: [TriviaQuestion]
}

struct TriviaQuestion: Decodable, Identifiable {
    let id: UUID = UUID() // Generated locally; not part of the payload
    let category: String
    let type: String       // "multiple" or "boolean"
    let difficulty: String // "easy", "medium", "hard"
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
    let allAnswersShuffled: [String] // Store shuffled answers once

    private enum CodingKeys: String, CodingKey {
        case category, type, difficulty, question, correct_answer, incorrect_answers
        // deliberately exclude `id` and `allAnswersShuffled`
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        type = try container.decode(String.self, forKey: .type)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        question = try container.decode(String.self, forKey: .question)
        correct_answer = try container.decode(String.self, forKey: .correct_answer)
        incorrect_answers = try container.decode([String].self, forKey: .incorrect_answers)
        
        // Shuffle answers once during initialization
        allAnswersShuffled = (incorrect_answers + [correct_answer]).shuffled()
    }
}
