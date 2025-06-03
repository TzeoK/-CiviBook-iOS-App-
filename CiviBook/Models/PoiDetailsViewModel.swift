import SwiftUI
import Foundation

class PoiDetailsViewModel: ObservableObject {
    @Published var events: [PoiEvent] = [] // event fields
    @Published var calendarEvents: [CalendarEvent] = [] // Expanded calendar events with individual dates
    @Published var isLoading = false
    @Published var errorMessage: String?
    

    func fetchEvents(for poiId: Int) async {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            DispatchQueue.main.async {
                self.errorMessage = "No token found."
            }
            return
        }

        let filter: [String: Any] = [
            "poi_id": poiId,
            "reservation_request": "accepted"
        ]
        
        guard let filterData = try? JSONSerialization.data(withJSONObject: filter),
              let filterString = String(data: filterData, encoding: .utf8),
              let url = URL(string: "http://192.168.1.240:8000/api/calendar-events?filter=\(filterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL or query string."
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            // Log the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            let decodedResponse = try JSONDecoder().decode(PoiEventResponse.self, from: data)

            // Process events to generate calendar data
            let calendarEvents = self.processEvents(decodedResponse.data)

            // Update UI on the main thread
            DispatchQueue.main.async {
                self.events = decodedResponse.data
                self.calendarEvents = calendarEvents
                self.isLoading = false
            }
        } catch {
            // Handle errors on the main thread
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                print("Detailed Error: \(error)")
                self.isLoading = false
            }
        }
    }

    // Turn events into CalendarEvents, the way requested by FSCalendar Libary
    private func processEvents(_ events: [PoiEvent]) -> [CalendarEvent] {
        var calendarEvents: [CalendarEvent] = []
        let dateFormatter = ISO8601DateFormatter()

        for event in events {
            guard let startDate = dateFormatter.date(from: event.eventStart),
                  let endDate = dateFormatter.date(from: event.eventEnd) else {
                print("Invalid date format for event: \(event)")
                continue
            }

            var currentDate = startDate
            let calendar = Calendar.current

            // Create multiple single day events for each multi-day event
            while currentDate <= endDate {
                let formattedDate = calendar.startOfDay(for: currentDate)
                calendarEvents.append(CalendarEvent(
                    title: event.name,
                    startDate: formattedDate,
                    endDate: nil,
                    id: event.id
                ))
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDay
            }
        }
        return calendarEvents
    }
}


struct PoiEventResponse: Codable {
    let data: [PoiEvent]
}


struct PoiEvent: Codable, Identifiable {
    let id: Int
    let name: String
    let eventStart: String
    let eventEnd: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case eventStart = "event_start"
        case eventEnd = "event_end"
    }
}

struct CalendarEvent {
    let title: String
    let startDate: Date
    let endDate: Date? // Optional; can be nil for single-day events
    let id: Int
}

// Helper Extension for ISO Date Conversion
extension Date {
    static func fromISOString(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: isoString)
    }
}
