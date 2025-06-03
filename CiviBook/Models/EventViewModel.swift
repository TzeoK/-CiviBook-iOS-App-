//
//  EventViewModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

import SwiftUI
import Combine

class EventViewModel: ObservableObject {
    @Published var events: [HomeTabEvent] = []
    @Published var pois: [POI] = []
    @Published var totalPages: Int = 1
    @Published var currentPage: Int = 1
    @Published var perPage: Int = 5
    @Published var selectedPOI: Int? = nil
    @Published var selectedCategory: String? = nil
    @Published var searchQuery: String = ""
    @Published var startDate: Date? = Calendar.current.startOfDay(for: Date()) // Today
    @Published var endDate: Date? = Calendar.current.date(byAdding: .day, value: 7, to: Date()) // One week later
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""



    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchPOIs()
        fetchFilteredEvents()
    }
    
    

    func fetchPOIs() {
        guard let url = URL(string: "http://192.168.1.240:8000/api/pois/all") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: POIResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Failed to fetch POIs: \(error.localizedDescription)"
                }
            }, receiveValue: { response in
                self.pois = response.data
            })
            .store(in: &cancellables)
    }


    func fetchFilteredEvents(resetPage: Bool = true) {
        if resetPage {
            currentPage = 1
            events = [] // Clear events when new filters are applied
        }

        var filterDict: [String: Any] = [:]

        if let selectedPOI = selectedPOI {
            filterDict["poi_id"] = selectedPOI
        }
        if let category = selectedCategory, !category.isEmpty {
            filterDict["category"] = category
        }
        if !searchQuery.isEmpty {
            filterDict["title"] = searchQuery
        }
        if let startDate = startDate {
            filterDict["date_range_start"] = formatDate(startDate)
        }
        if let endDate = endDate {
            filterDict["date_range_end"] = formatDate(endDate)
        }

        // Convert filter dictionary to JSON string
        let filterJSONString: String
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: filterDict, options: [])
            filterJSONString = String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Failed to encode filter JSON")
            return
        }

        // Construct the full URL with the filter JSON in the query string
        var components = URLComponents(string: "http://192.168.1.240:8000/api/events-authenticated")
        components?.queryItems = [
            URLQueryItem(name: "filter", value: filterJSONString),
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "perPage", value: "\(perPage)")
        ]

        guard let finalURL = components?.url else {
            print("Invalid URL with filters")
            return
        }

        print("Sending Request to: \(finalURL.absoluteString)")

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"

        // Include Authentication Token
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("No Auth Token Found!")
            errorMessage = "Authentication required. Please log in."
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching events: \(error.localizedDescription)"
                    print("❌ API Request Failed: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid HTTP response")
                    return
                }

                print("📡 HTTP Response Status: \(httpResponse.statusCode)")

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(EventTabResponse.self, from: data)

                    if resetPage {
                        self.events = decodedResponse.data // Replace events on filter change
                    } else {
                        self.events.append(contentsOf: decodedResponse.data) // Append only when loading more pages
                    }

                    self.totalPages = decodedResponse.lastPage ?? 1
                    print(" Successfully decoded response. Events Count: \(self.events.count)")

                } catch {
                    self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("❌ Decoding Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func applyFilters() {
        currentPage = 1
        fetchFilteredEvents()
    }



    func fetchMoreEvents() {
            if currentPage < totalPages {
                currentPage += 1
                fetchFilteredEvents(resetPage: false)
            }
        }


    func resetFilters() {
        selectedPOI = nil
        selectedCategory = nil
        searchQuery = ""
        startDate = nil
        endDate = nil
        fetchFilteredEvents()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    

}


struct EventTabResponse: Codable {
    let data: [HomeTabEvent] // Event data array
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case data
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }
}









