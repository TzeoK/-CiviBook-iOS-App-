//
//  CalendarViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var calendarPois: [POI] = []
    @Published var selectedPOI: Int? = nil
    @Published var calendarEvents: [HomeTabEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedEvent: HomeTabEvent? = nil //stores the whole event that is selected to load it to the event view card

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchPOIs()
    }

    func fetchPOIs() {
        guard let url = URL(string: "http://192.168.1.240:8000/api/pois/calendar") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: POIResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Αποτυχία φόρτωσης τοποθεσιών: \(error.localizedDescription)"
                }
            }, receiveValue: { response in
                self.calendarPois = response.data
            })
            .store(in: &cancellables)
    }

    func fetchEvents() async {
        guard let poiID = selectedPOI else { return }
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            DispatchQueue.main.async { self.errorMessage = "No auth token found. Please log in." }
            return
        }

        let filter: [String: Any] = [
            "poi_id": poiID,
            "reservation_request": "accepted"
        ]
        
        guard let filterData = try? JSONSerialization.data(withJSONObject: filter),
              let filterString = String(data: filterData, encoding: .utf8),
              let url = URL(string: "http://192.168.1.240:8000/api/calendar-events-full?filter=\(filterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
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
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            // Log the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📡 Raw API Response: \(jsonString)")
            }

            let decodedResponse = try JSONDecoder().decode(HomeTabEventResponse.self, from: data)

            DispatchQueue.main.async {
                self.calendarEvents = decodedResponse.data
                self.updateCalendarEventsWithNewData(decodedResponse.data)
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                print("Detailed Error: \(error)")
                self.isLoading = false
            }
        }
    }

    
    func toggleLike(for event: HomeTabEvent) {
        DispatchQueue.main.async {
            event.isLiked.toggle() 
            Task {
                self.performLikeRequest(for: event, isCurrentlyLiked: !event.isLiked)
                await self.fetchEvents()
            }
        }
    }

    private func performLikeRequest(for event: HomeTabEvent, isCurrentlyLiked: Bool) {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else { return }

        let eventId = event.id
        let urlString = isCurrentlyLiked
            ? "http://192.168.1.240:8000/api/events/\(eventId)/unlike"
            : "http://192.168.1.240:8000/api/events/\(eventId)/like"

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = isCurrentlyLiked ? "DELETE" : "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    event.isLiked = !isCurrentlyLiked
                }
            }
        }.resume()
    }

    
    private func updateCalendarEventsWithNewData(_ newEvents: [HomeTabEvent]) {
        for newEvent in newEvents {
            if let index = calendarEvents.firstIndex(where: { $0.id == newEvent.id }) {
                calendarEvents[index] = newEvent
            }
        }
    }



}
