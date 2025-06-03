//
//  ChangePasswordViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 23/5/25.
//

import SwiftUI

class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    @Published var errorMessage: String? // General error
    @Published var fieldErrors: [String: String] = [:] // Field-specific errors

    @Published var isPasswordChanged: Bool = false

    func changePassword() {
        errorMessage = nil
        fieldErrors.removeAll()

        guard let url = URL(string: "http://192.168.1.240:8000/api/change-password") else {
            errorMessage = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let parameters: [String: String] = [
            "current_password": currentPassword,
            "new_password": newPassword,
            "new_password_confirmation": confirmPassword
        ]


        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            errorMessage = "Failed to encode request"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No response data received"
                    return
                }

                print("📡 Status Code: \(httpResponse.statusCode)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("📥 Raw Response: \(raw)")
                }

                switch httpResponse.statusCode {
                case 200:
                    self.isPasswordChanged = true

                case 422:
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        if let errors = json?["errors"] as? [String: [String]] {
                            self.fieldErrors = errors.reduce(into: [:]) { result, item in
                                let (key, value) = item
                                let camelCaseKey = self.convertToCamelCase(key)
                                result[camelCaseKey] = value.first ?? "Invalid input"
                            }
                        } else {
                            self.errorMessage = "Validation failed. Unknown error format."
                        }
                    } catch {
                        self.errorMessage = "JSON parsing error: \(error.localizedDescription)"
                    }

                default:
                    self.errorMessage = "Unexpected error (Status: \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }

    // Laravel snake_case to camelCase
    private func convertToCamelCase(_ key: String) -> String {
        let parts = key.split(separator: "_")
        guard let first = parts.first else { return key }
        return ([String(first)] + parts.dropFirst().map { $0.capitalized }).joined()
    }
}
