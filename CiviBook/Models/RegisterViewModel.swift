import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""

    @Published var errorMessage: String? // General error
    @Published var fieldErrors: [String: String] = [:] // Field-specific errors

    @Published var isRegistered: Bool = false
    @Published var navigateToLogin: Bool = false

    func register() {
        errorMessage = nil
        fieldErrors.removeAll() // Clear previous errors
        
        // Local Validation
        if username.isEmpty { fieldErrors["username"] = "Το Username είναι απαραίτητο " }
        if firstName.isEmpty { fieldErrors["firstName"] = "Το όνομα είναι απαραίτητο" }
        if lastName.isEmpty { fieldErrors["lastName"] = "Το επώνυμο είναι απαραίτητο" }
        if email.isEmpty || !email.contains("@") { fieldErrors["email"] = "Εισάγετε μια έγκυρη διεύθυνση email" }
        if password.isEmpty { fieldErrors["password"] = "Ο κωδικός είναι απαραίτητος" }
        else if password.count < 6 { fieldErrors["password"] = "Ο κωδικός πρέπει να είναι τουλάχιστον 6 χαρακτήρες" }
        if passwordConfirmation.isEmpty { fieldErrors["passwordConfirmation"] = "Επιβεβαίωση κωδικού" }
        if password != passwordConfirmation { fieldErrors["passwordConfirmation"] = "Οι κωδικοί δεν ταιριάζουν" }

        // If local validation fails, stop the request
        if !fieldErrors.isEmpty {
            print("Local Validation Errors: \(fieldErrors)")
            return
        }

        guard let url = URL(string: "http://192.168.1.240:8000/api/register") else {
            errorMessage = "Invalid URL"
            return
        }

        let body: [String: Any] = [
            "username": username,
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "password": password,
            "password_confirmation": passwordConfirmation
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Force JSON response

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Failed to encode request"
            return
        }

        print("Sending API Request to: \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                print("HTTP Response Status: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    self.isRegistered = true
                    print("Registration successful!")
                } else if httpResponse.statusCode == 422 {
                    // Handle Laravel Validation Errors (Convert snake_case to camelCase)
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errors = json["errors"] as? [String: [String]] {
                        self.fieldErrors = errors.reduce(into: [:]) { result, item in
                            let (key, value) = item
                            let camelCaseKey = self.convertToCamelCase(key)
                            result[camelCaseKey] = value.first ?? "Invalid input"
                        }
                        print("❌ Laravel Validation Errors: \(self.fieldErrors)")
                    } else {
                        self.errorMessage = "Unknown validation error"
                    }
                } else {
                    self.errorMessage = "Unexpected error. Try again."
                }
            }
        }.resume()

    }
    
    func convertToCamelCase(_ key: String) -> String {
        let components = key.split(separator: "_").map { String($0) } //We convert to String array
        guard let first = components.first else { return key } //We ensure there is at least one component
        let rest = components.dropFirst().map { $0.capitalized } //We capitalize subsequent words
        return ([first] + rest).joined() // Concatenate
    }
}


