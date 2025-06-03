//
//  EditProfileViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 3/3/25.
//

import SwiftUI

class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var selectedImage: UIImage? = nil
    @Published var showImagePicker: Bool = false


    @Published var errorMessage: String? // General error
    @Published var fieldErrors: [String: String] = [:] // Field-specific errors

    @Published var isUpdated: Bool = false
    let user: User // Current logged-in user

    init(user: User) {
        self.user = user
        self.firstName = user.first_name
        self.lastName = user.last_name
        self.username = user.username
        self.email = user.email
        self.phoneNumber = user.phone_number ?? ""
    }

    func updateProfile() {
        errorMessage = nil
        fieldErrors.removeAll()

        guard let url = URL(string: "http://192.168.1.240:8000/api/edit-profile-post-data") else {
            errorMessage = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"  // Laravel uses method PUT so we are going to simulate it
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Adds `_method=PUT` to simulate a PUT request
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"_method\"\r\n\r\n".data(using: .utf8)!)
        body.append("PUT\r\n".data(using: .utf8)!)

        let params: [String: String] = [
            "first_name": firstName,
            "last_name": lastName,
            "username": username,
            "email": email,
            "phone_number": phoneNumber
        ]

        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add profile image if exists
        if let selectedImage = selectedImage,
           let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            let filename = "profile.jpg"
            let mimetype = "image/jpeg"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile_img\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("Sending API Request to: \(url.absoluteString)")

        // Send Request
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

                // Log Raw API Response Before Parsing
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw API Response: \(rawResponse)")
                }

                print("HTTP Response Status: \(httpResponse.statusCode)")

                // Handle Success (200)
                if httpResponse.statusCode == 200 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let userData = json["data"] as? [String: Any] {
                                self.isUpdated = true
                                print("Profile updated successfully!")
                            } else {
                                self.errorMessage = " No user data returned"
                            }
                        } else {
                            self.errorMessage = "Unexpected response format"
                        }
                    } catch {
                        self.errorMessage = "JSON Parsing Error: \(error.localizedDescription)"
                    }

                // Handle Laravel Validation Errors (422)
                } else if httpResponse.statusCode == 422 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        print("📥 Parsed JSON: \(json ?? [:])")

                        if let errors = json?["errors"] as? [String: [String]] {
                            self.fieldErrors = errors.reduce(into: [:]) { result, item in
                                let (key, value) = item
                                let camelCaseKey = self.convertToCamelCase(key)
                                result[camelCaseKey] = value.first ?? "Invalid input"
                            }
                            print("Laravel Validation Errors: \(self.fieldErrors)")
                        } else {
                            self.errorMessage = "Validation failed, but error format unknown."
                        }
                    } catch {
                        self.errorMessage = "JSON Parsing Error: \(error.localizedDescription)"
                        print("JSON Parsing Error: \(error.localizedDescription)")
                    }

                } else {
                    self.errorMessage = "Unexpected error (Status: \(httpResponse.statusCode)). Try again."
                }
            }
        }.resume()
    }


    // Convert Laravel snake_case errors to camelCase
    func convertToCamelCase(_ key: String) -> String {
        let components = key.split(separator: "_").map { String($0) }
        guard let first = components.first else { return key }
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }



    

}
