//
//  ForgetPasswordViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 19/3/25.
//

import SwiftUI
import Combine

class ForgetPasswordViewModel: ObservableObject {
    @Published var email = ""       // User input for email
    @Published var message = ""     // Success or error message
    @Published var isError = false  // Tracks if message is an error

    private var cancellables = Set<AnyCancellable>() // Manage Combine requests

    func sendResetLink() {
        guard !email.isEmpty else {
            self.message = "Please enter your email."
            self.isError = true
            return
        }

        guard let url = URL(string: "http://192.168.1.240:8000/api/forgetpassword") else {
            self.message = "Invalid API URL."
            self.isError = true
            return
        }

        let parameters = ["email": email]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.message = "Failed to serialize request."
            self.isError = true
            return
        }

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔹 Server Response: \(jsonString)")
                }

                if httpResponse.statusCode == 200 {
                    return data
                } else {
                    let serverError = try JSONDecoder().decode(ServerError.self, from: data)
                    throw LoginError.custom(serverError.message)
                }
            }
            .decode(type: ForgetPasswordResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error as LoginError):
                    self.message = error.localizedDescription
                    self.isError = true
                case .failure(let error):
                    self.message = "Request failed: \(error.localizedDescription)"
                    self.isError = true
                case .finished:
                    break
                }
            }, receiveValue: { response in
                self.message = response.message
                self.isError = false
            })
            .store(in: &cancellables)
    }
}

// MARK: - Models

struct ForgetPasswordResponse: Codable {
    var message: String
}



