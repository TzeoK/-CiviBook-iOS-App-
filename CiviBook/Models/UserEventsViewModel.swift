//
//  UserEventsViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/1/25.
//

import Foundation
import SwiftUI

class UserEventsViewModel: ObservableObject {
    @Published var events: [UserEvent] = []
    @Published var isLoading = false
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    func fetchUserEvents(for userId: String) {
        isLoading = true
        guard let url = URL(string: "http://192.168.1.240:8000/api/user-events") else {
            print("Invalid URL.")
            return
        }
        
        // Get the authorization token from your login view model (assuming it's stored there)
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Authorization token is missing.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error fetching user events: \(error.localizedDescription)")
                    return
                }
                
                // Check for a successful status code
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("HTTP Error: Status code \(httpResponse.statusCode)")
                    return
                }
                
                // Log the raw data to inspect it
                if let data = data, let stringData = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(stringData)")
                }
                
                // Try to decode the JSON response
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(UserEventsResponse.self, from: data)
                        self.events = decodedResponse.events
                        
                        print("Fetched Events: \(self.events)")
                    } catch {
                        print("Error decoding user events: \(error)")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - User Created Event Model
struct UserEvent: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String
    let category: String
    let contactNumber: String? // Nullable fields are optional
    let createdAt: String
    let updatedAt: String
    let entryCost: String?
    let eventStart: String
    let eventEnd: String
    let eventStartDate: String?
    let eventEndDate: String?
    let eventStartTime: String
    let imgPath: String?
    let likes: Int
    let reservationRequest: String
    let recurringDays: String?
    let poi: POI // Nested POI
    
    // DateFormatter for Greek localization
    private var greekDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "el_GR") // Greek locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    // Function to convert ISO 8601 string to Date
    private func convertISOToDate(_ isoString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: isoString)
    }
    
    // Computed property to get formatted start date in Greek format
    var formattedStartDate: String? {
        guard let startDate = convertISOToDate(eventStart) else { return nil }
        return greekDateFormatter.string(from: startDate)
    }
    
    // Computed property to get formatted end date in Greek format
    var formattedEndDate: String? {
        guard let endDate = convertISOToDate(eventEnd) else { return nil }
        return greekDateFormatter.string(from: endDate)
    }
    
    // Computed property to translate reservation request status to Greek
    var translatedReservationStatus: String {
        switch reservationRequest.lowercased() {
        case "accepted":
            return "Έγκρίθηκε"
        case "declined":
            return "Απορρίφθηκε"
        case "pending":
            return "Σε Αναμονή"
        default:
            return "Άγνωστο"
        }
    }
    
    struct POI: Decodable {
        let id: Int
        let name: String
        let description: String
        let address: String
        let latitude: String
        let longitude: String
        let poiImg: String? // Use snake_case mapping for this
    }
}

// Model for the response
struct UserEventsResponse: Decodable {
    let events: [UserEvent]
}

// CodingKeys to handle snake_case
extension UserEvent {
    private enum CodingKeys: String, CodingKey {
        case id, name, description, category, likes, poi
        case contactNumber = "contact_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case entryCost = "entry_cost"
        case eventStart = "event_start"
        case eventEnd = "event_end"
        case eventStartDate = "event_start_date"
        case eventEndDate = "event_end_date"
        case eventStartTime = "event_start_time"
        case imgPath = "img_path"
        case reservationRequest = "reservation_request"
        case recurringDays = "recurring_days"
    }
}

extension UserEvent.POI {
    private enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude
        case poiImg = "poi_img"
    }
}
