//
//  TrackedEventsViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 11/2/25.
//

import SwiftUI

class TrackedEventsViewModel: ObservableObject {
    @Published var trackedEvents: [TrackedEvent] = []
    @Published var isLoading = false

    func fetchTrackedEvents() {
        isLoading = true
        guard let url = URL(string: "http://192.168.1.240:8000/api/tracked-events") else {
            print("Invalid URL.")
            return
        }

        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Authorization token is missing.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error fetching tracked events: \(error.localizedDescription)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("HTTP Error: Status code \(httpResponse.statusCode)")
                    return
                }
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(TrackedEventsResponse.self, from: data)
                        self.trackedEvents = decodedResponse.events
                    } catch {
                        print("Error decoding tracked events: \(error)")
                    }
                }
            }
        }.resume()
    }
}

struct TrackedEventsResponse: Decodable {
    let events: [TrackedEvent]
}

struct TrackedEvent: Identifiable, Decodable {
    let id: Int
    let name: String
    let poi_name: String
    let event_start_date: String
    let event_end_date: String
    let event_start_time: String

    // DateFormatter for Greek localization
        private var greekDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "el_GR") // Greek locale
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            return formatter
        }

        // Function to convert "yyyy-MM-dd" string to Date
        private func convertToDate(_ dateString: String) -> Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString)
        }

        // Computed property to get formatted start date in Greek format
        var formattedStartDate: String? {
            guard let startDate = convertToDate(event_start_date) else { return nil }
            return greekDateFormatter.string(from: startDate)
        }

        // Computed property to get formatted end date in Greek format
        var formattedEndDate: String? {
            guard let endDate = convertToDate(event_end_date) else { return nil }
            return greekDateFormatter.string(from: endDate)
        }
}


