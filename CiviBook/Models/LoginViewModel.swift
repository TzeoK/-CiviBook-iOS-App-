//
//  LoginViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 12/1/25.
//

import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    @Published var identifier = ""          // For email or username
    @Published var password = ""            // User's password
    @Published var isLoggedIn = false       // Tracks login state
    @Published var errorMessage = ""        // Error message for the user
    @Published var user: User?              // Stores the logged-in user's details
    @Published var isLoggedOut: Bool = true
    
    private var cancellables = Set<AnyCancellable>()  // For managing Combine publishers
    
    init() {
            checkForStoredToken()  // check token on app launch
        }
        
    private func checkForStoredToken() {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            print("Found stored auth token: \(token)")

            if let userData = UserDefaults.standard.data(forKey: "userData"),
               let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
                DispatchQueue.main.async {
                    self.user = savedUser
                    self.isLoggedIn = true
                    print("User restored: \(savedUser.username)")
                }
            }

            //  Fetch latest user info, but don't log out if it fails
            fetchUserProfile()
        } else {
            print("No auth token found, user needs to log in")
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.user = nil
            }
        }
    }




    func fetchUserProfile() {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("❌ No auth token, user not logged in")
            return
        }

        let url = URL(string: "http://192.168.1.240:8000/api/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Failed to fetch user profile: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❌ No data received")
                return
            }

            do {
                let decodedUser = try JSONDecoder().decode(User.self, from: data)
                
                DispatchQueue.main.async {
                    print("User profile updated: \(decodedUser.username)")
                    
                    // Update user state in ViewModel
                    self.user = decodedUser
                    self.isLoggedIn = true

                    // Save updated user to UserDefaults
                    if let encodedUser = try? JSONEncoder().encode(decodedUser) {
                        UserDefaults.standard.set(encodedUser, forKey: "userData")
                        print("Updated user stored in UserDefaults")
                    }
                    self.printStoredUserData()
                }
            } catch {
                print("Failed to decode user profile: \(error.localizedDescription)")
            }
        }.resume()
    }

    func printStoredUserData() {
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            print("Stored User Data in UserDefaults:")
            print("Username: \(savedUser.username)")
            print("First Name: \(savedUser.first_name)")
            print("Last Name: \(savedUser.last_name)")
            print("Email: \(savedUser.email)")
        } else {
            print("No user data found in UserDefaults.")
        }
    }

    
    func login() {
        // Log the form values
        print("Logging in with:")
        print("Identifier: \(identifier)")
        print("Password: \(password)")
        
        guard let url = URL(string: "http://192.168.1.240:8000/api/login") else {
            errorMessage = "Invalid URL"
            return
        }
        
        // Request parameters
        let parameters = [
            "identifier": identifier,  // Email or username
            "password": password       // Password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Serialize parameters into JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            // Log the serialized JSON for debugging
            if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                print("Request JSON: \(jsonString)")
            }
        } catch {
            errorMessage = "Error serializing data."
            return
        }
        
        // Make the network request
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Ensure a valid HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw Server Response: \(jsonString)") // Log the raw response
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 401:
                    let serverError = try JSONDecoder().decode(ServerError.self, from: data)
                    throw LoginError.custom(serverError.message)
                default:
                    throw URLError(.badServerResponse)
                }
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)  // Ensure updates happen on the main thread
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error as LoginError):
                    self.errorMessage = error.localizedDescription
                case .failure(let error):
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                case .finished:
                    break
                }
            }, receiveValue: { response in
                // On success, update the state and save the token
                self.isLoggedIn = true
                self.isLoggedOut = false //
                
                UserDefaults.standard.set(response.token, forKey: "authToken")  // Store token
                self.user = response.user                                      // Store user details
                self.errorMessage = ""
                // Clear any errors
                if let encodedUser = try? JSONEncoder().encode(response.user) {
                                UserDefaults.standard.set(encodedUser, forKey: "userData")
                            }
                
                if let imageURL = self.user?.fullProfileImageURL {
                    print("Profile Image URL: \(imageURL)")  // Log it here
                } else {
                    print("No profile image available.")
                }
            })
            .store(in: &cancellables)  // Store the cancellable to manage lifecycle
    }

    
    func logout() {
        isLoggedOut = true
        isLoggedIn = false
        user = nil
        identifier = ""
        password = ""

        // Remove stored data
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userData")

        print("User logged out and data cleared.")
    }
    
    
}

// MARK: - Models

struct LoginResponse: Codable {
    var message: String
    var token: String
    var user: User
}

struct User: Codable {
    var id: Int
    var username: String
    var first_name: String
    var last_name: String
    var phone_number: String?
    var email: String
    var is_admin: Int
    var profile_img: String?
    var email_verified_at: String?
    var created_at: String
    var updated_at: String
    var fullProfileImageURL: URL? {
        guard let imagePath = profile_img else { return nil }
        // Construct full URL by combining the base URL with the relative path
        let baseURL = "http://192.168.1.240:8000/storage/"
        let fullURLString = baseURL + imagePath
        return URL(string: fullURLString)
    }
}

// MARK: - Custom Errors

enum LoginError: LocalizedError {
    case invalidCredentials
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .custom(let message):
            return message
        }
    }
}


struct ServerError: Codable {
    let message: String
}
