import SwiftUI
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var homeData: [String] = [] // Example data for Home tab
    @Published var bookingsData: [String] = [] // Example data for Bookings tab
    @Published var calendarData: [String] = [] // Example data for Calendar tab
    @Published var eventsData: [String] = [] // Example data for Events tab
    @Published var notificationsData: [String] = [] // Example data for Notifications tab
    
    @Published var pois: [POI] = [] // To store all POI data
    @Published var totalPOIs: Int = 0 // To store the total count of POIs
    @Published var isLoading: Bool = false // To indicate loading state
    @Published var errorMessage: String = "" // To display errors, if any
    
    @Published var todayEvents: [HomeTabEvent] = []
    @Published var thisWeekEvents: [HomeTabEvent] = []
    @Published var thisMonthEvents: [HomeTabEvent] = []
    @Published var nextMonthEvents: [HomeTabEvent] = []
    
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    
    private var timer: AnyCancellable?
    
    //for passing to the event details view
    @Published var isTracked: Bool = false
    
    //variables related to filtering on the events tab
    @Published var filteredEvents: [HomeTabEvent] = []
    
    // Filters
        @Published var selectedPOI: Int? = nil
        @Published var selectedCategory: String = "All"
        @Published var searchQuery: String = ""
        @Published var startDate: Date? = nil
        @Published var endDate: Date? = nil

        // Pagination
        @Published var page: Int = 1
        @Published var perPage: Int = 5
        @Published var totalPages: Int = 1
    
    init() {
        // Initialize data
        fetchDailyEvents()
        fetchWeeklyEvents()
        fetchMonthlyEvents()
        fetchNextMonthEvents()
        if pois.isEmpty {
                fetchPOIs()
            }
        
        startAutoRefresh()
    }
    
    func fetchPOIs() {
        guard let url = URL(string: "http://192.168.1.240:8000/api/pois/all") else {
            errorMessage = "Invalid URL"
            return
        }
        print("entered pois")
        isLoading = true
        errorMessage = ""
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    print("entered do")
                    let decodedResponse = try JSONDecoder().decode(POIResponse.self, from: data)
                    self?.pois = decodedResponse.data
                    self?.totalPOIs = decodedResponse.total
                    
                    print("Fetched POIs: \(self?.pois ?? [])")
                    print("Total POIs: \(self?.totalPOIs ?? 0)")
        
                    
                    for poi in self?.pois ?? [] {
                        print("POI ID: \(poi.id)")
                        print("POI Name: \(poi.name)")
                        print("POI Address: \(poi.address)")
                        print("POI Latitude: \(poi.latitude)")
                        print("POI Longitude: \(poi.longitude)")
                        if let poiImage = poi.poi_img {
                            print("POI Image: \(poiImage)")
                        } else {
                            print("POI Image: nil")
                        }
                        print("POI Created At: \(poi.created_at)")
                        print("POI Updated At: \(poi.updated_at)")
                        print("---") // Separator for each POI
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func toggleLike(for event: HomeTabEvent) {
        DispatchQueue.main.async {
            print(event.isLiked)
            self.performLikeRequest(for: event, isCurrentlyLiked: event.isLiked)
        }
    }
    
    private func performLikeRequest(for event: HomeTabEvent, isCurrentlyLiked: Bool) {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("❌ No auth token found, user might not be logged in.")
            return
        }
        
        let eventId = event.id
        let urlString = isCurrentlyLiked
        ? "http://192.168.1.240:8000/api/events/\(eventId)/unlike"
        : "http://192.168.1.240:8000/api/events/\(eventId)/like"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isCurrentlyLiked ? "DELETE" : "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
//                print("❌ API Request Failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
//                print("❌ No data received from API")
                return
            }
            
            
            if let jsonString = String(data: data, encoding: .utf8) {
//                print("📡 Raw API Response: \(jsonString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(LikeResponse.self, from: data)
                DispatchQueue.main.async {
                    event.likes = decodedResponse.likes
                    event.isLiked = !isCurrentlyLiked
                }
            } catch {
                print("❌ Failed to decode response: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /// Fetch notifications from backend
    func fetchNotifications() {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("No auth token found.")
            return
        }
        
        guard let url = URL(string: "http://192.168.1.240:8000/api/notifications") else {
            print("Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received.")
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(NotificationResponse.self, from: data)
                    self?.notifications = decodedResponse.notifications
                    self?.unreadCount = decodedResponse.notifications.filter { $0.read_at == nil }.count
                } catch {
                    print("Failed to decode notifications: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func markNotificationAsRead(notificationId: String) {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else { return }

        guard let url = URL(string: "http://192.168.1.240:8000/api/notifications/\(notificationId)/read") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                    self?.notifications[index].read_at = ISO8601DateFormatter().string(from: Date()) // Mark as read
                    self?.unreadCount -= 1 // Decrease unread count
                }
            }
        }.resume()
    }

    
    /// Starts automatic notification refresh every 30 seconds
    func startAutoRefresh() {
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchNotifications()
            }
    }
    
    /// Stops the timer when not needed
    func stopAutoRefresh() {
        timer?.cancel()
    }
    
    
    
    //For all events update liked state when pull to refresh for example- Called from within fetchEvents to update ui
    private func updateEventsWithNewData(_ newEvents: [HomeTabEvent]) {
        for newEvent in newEvents {
            if let index = todayEvents.firstIndex(where: { $0.id == newEvent.id }) {
                todayEvents[index] = newEvent
            }
            if let index = thisWeekEvents.firstIndex(where: { $0.id == newEvent.id }) {
                thisWeekEvents[index] = newEvent
            }
            if let index = thisMonthEvents.firstIndex(where: { $0.id == newEvent.id }) {
                thisMonthEvents[index] = newEvent
            }
            if let index = nextMonthEvents.firstIndex(where: { $0.id == newEvent.id }) {
                nextMonthEvents[index] = newEvent
            }
        }
    }
    
    
    func fetchHomeData() {
        // Fetch or generate data for Home tab
        homeData = ["Welcome Item 1", "Welcome Item 2"]
        
        // Print home data
        print("Home Data: \(homeData)")
    }
    
    func fetchBookingsData() {
        bookingsData = ["Booking 1", "Booking 2"]
        
        // Print bookings data
        print("Bookings Data: \(bookingsData)")
    }
    
    func fetchCalendarData() {
        calendarData = ["Event 1", "Event 2"]
        
        // Print calendar data
        print("Calendar Data: \(calendarData)")
    }
    
    func fetchEventsData() {
        eventsData = ["Concert", "Workshop"]
        
        // Print events data
        print("Events Data: \(eventsData)")
    }
    
    func fetchNotificationsData() {
        notificationsData = ["Notification 1", "Notification 2"]
        
        // Print notifications data
        print("Notifications Data: \(notificationsData)")
    }
    
    /// Fetch events happening today
    func fetchDailyEvents() {
        fetchEvents(from: "http://192.168.1.240:8000/api/daily-events-auth") { events in
            DispatchQueue.main.async {
                self.todayEvents = events
                print("Fetched \(events.count) daily events")
            }
        }
    }
    
    /// Fetch events happening  this week
    func fetchWeeklyEvents() {
        fetchEvents(from: "http://192.168.1.240:8000/api/weekly-events-auth") { events in
            DispatchQueue.main.async {
                self.thisWeekEvents = events
                print("Fetched \(events.count) weekly events")
            }
        }
    }
    
    /// Fetch events happening this month
    func fetchMonthlyEvents() {
        fetchEvents(from: "http://192.168.1.240:8000/api/monthly-events-auth") { events in
            DispatchQueue.main.async {
                self.thisMonthEvents = events
                print("Fetched \(events.count) monthly events")
            }
        }
    }
    
    /// Fetch events happening next month
    func fetchNextMonthEvents() {
        fetchEvents(from: "http://192.168.1.240:8000/api/next-month-events-auth") { events in
            DispatchQueue.main.async {
                self.nextMonthEvents = events
                print("Fetched \(events.count) next month events")
            }
        }
    }
    
    //General use fetch events function that takes a string as url that returns full events details
    private func fetchEvents(from urlString: String, completion: @escaping ([HomeTabEvent]) -> Void) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL: \(urlString)" }
            return
        }
        
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            DispatchQueue.main.async { self.errorMessage = "No auth token found. Please log in." }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = "Error: \(error.localizedDescription)" }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                return
            }
            
            do {
                let jsonString = String(data: data, encoding: .utf8) ?? "No JSON"
                print("📡 Raw API Response: \(jsonString)")
                
                let decodedResponse = try JSONDecoder().decode(HomeTabEventResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(decodedResponse.data)
                    self.updateEventsWithNewData(decodedResponse.data)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    
    
    //This function is used to fetch the full detailes of a particular event matching its ID (useful for cases where full event details are not available
    func fetchEventDetails(eventId: Int, completion: @escaping (HomeTabEvent?) -> Void) {
        guard let url = URL(string: "http://192.168.1.240:8000/api/view-event-auth/\(eventId)") else {
            print("Invalid URL.")
            completion(nil)
            return
        }
        
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Authorization token is missing.")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching event details: \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP Error: Status code \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            if let data = data {
                do {
                    let decodedEvent = try JSONDecoder().decode(HomeTabEvent.self, from: data)
                    DispatchQueue.main.async {
                        completion(decodedEvent)
                    }
                } catch {
                    print("Error decoding event details: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    //Helper function for th eventDetailsView to check if the event is tracked so as not to include is_tracked since only that view requires it
    func checkIfTracked(eventId: Int) {
        guard let url = URL(string: "http://192.168.1.240:8000/api/events/\(eventId)/isTracked") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("No Auth Token Found!")
            DispatchQueue.main.async {
                self.errorMessage = "Authentication required. Please log in."
            }
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error checking track status: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let result = try JSONDecoder().decode(TrackStatusResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isTracked = result.isTracked
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Function to track the event
        func trackEvent(eventId: Int) {
            guard let url = URL(string: "http://192.168.1.240:8000/api/events/\(eventId)/track") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            // fetch token
            if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            } else {
                print("No Auth Token Found!")
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required. Please log in."
                }
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.isTracked = true // Update to reflect the tracking status
                }
            }
            task.resume()
        }
        
        // Function to untrack the event
        func untrackEvent(eventId: Int) {
            guard let url = URL(string: "http://192.168.1.240:8000/api/events/\(eventId)/untrack") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"

            // Fetch token
            if let authToken = UserDefaults.standard.string(forKey: "authToken") {
                request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            } else {
                print("No Auth Token Found!")
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required. Please log in."
                }
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.isTracked = false // Update to reflect the untracking status
                }
            }
            task.resume()
        }


}



// MARK: - POI Models
struct POIResponse: Codable {
    let data: [POI]
    let total: Int
}

struct POI: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let address: String
    let place_name: String?
    let display_address: String?
    let latitude: String
    let longitude: String
    let poi_img: String?
    let created_at: String
    let updated_at: String
}

struct LikeResponse: Codable {
    let likes: Int
}

struct HomeTabEventResponse: Codable {
    let data: [HomeTabEvent]
}
class HomeTabEvent: ObservableObject, Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let category: String
    let eventStartDate: String
    let eventEndDate: String
    let eventStart: String
    let eventEnd: String
    let reservationRequest: String?
    let poiId: Int
    let imgPath: String?
    let entryCost: String?
    let eventStartTime: String?
    let poi: POI
    let recurringDays: [Int]
    
    @Published var likes: Int
    @Published var isLiked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, poiId = "poi_id"
        case eventStartDate = "event_start_date"
        case eventEndDate = "event_end_date"
        case eventStart = "event_start"
        case eventEnd = "event_end"
        case reservationRequest = "reservation_request"
        case recurringDays = "recurring_days"
        case imgPath = "img_path"
        case entryCost = "entry_cost"
        case eventStartTime = "event_start_time"
        case likes, isLiked, poi
    }
    
    init(id: Int, name: String, description: String, category: String, eventStartDate: String, eventEndDate: String, eventStart: String, eventEnd: String, reservationRequest: String?, poiId: Int, recurringDays: [Int], imgPath: String?, entryCost: String?, eventStartTime: String?, likes: Int, isLiked: Bool, poi: POI) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.eventStartDate = eventStartDate
        self.eventEndDate = eventEndDate
        self.eventStart = eventStart
        self.eventEnd = eventEnd
        self.reservationRequest = reservationRequest
        self.poiId = poiId
        self.recurringDays = recurringDays
        self.imgPath = imgPath
        self.entryCost = entryCost
        self.eventStartTime = eventStartTime
        self.poi = poi
        
        self.likes = likes
        self.isLiked = isLiked
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        eventStartDate = try container.decode(String.self, forKey: .eventStartDate)
        eventEndDate = try container.decode(String.self, forKey: .eventEndDate)
        eventStart = try container.decode(String.self, forKey: .eventStart)
        eventEnd = try container.decode(String.self, forKey: .eventEnd)
        reservationRequest = try container.decodeIfPresent(String.self, forKey: .reservationRequest)
        poiId = try container.decode(Int.self, forKey: .poiId)
        imgPath = try container.decodeIfPresent(String.self, forKey: .imgPath)
        entryCost = try container.decodeIfPresent(String.self, forKey: .entryCost)
        eventStartTime = try container.decodeIfPresent(String.self, forKey: .eventStartTime)
        poi = try container.decode(POI.self, forKey: .poi)
        
        _likes = Published(initialValue: try container.decode(Int.self, forKey: .likes))
        _isLiked = Published(initialValue: try container.decode(Bool.self, forKey: .isLiked))
        
        let recurringDaysString = try container.decode(String.self, forKey: .recurringDays)
        if let data = recurringDaysString.data(using: .utf8) {
            recurringDays = (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        } else {
            recurringDays = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(eventStartDate, forKey: .eventStartDate)
        try container.encode(eventEndDate, forKey: .eventEndDate)
        try container.encode(eventStart, forKey: .eventStart)
        try container.encode(eventEnd, forKey: .eventEnd)
        try container.encodeIfPresent(reservationRequest, forKey: .reservationRequest)
        try container.encode(poiId, forKey: .poiId)
        try container.encodeIfPresent(imgPath, forKey: .imgPath)
        try container.encodeIfPresent(entryCost, forKey: .entryCost)
        try container.encodeIfPresent(eventStartTime, forKey: .eventStartTime)
        try container.encode(poi, forKey: .poi)
        
        
        try container.encode(likes, forKey: .likes)
        try container.encode(isLiked, forKey: .isLiked)
        
        try container.encode(recurringDays, forKey: .recurringDays)
    }
}

struct TrackStatusResponse: Decodable {
    let isTracked: Bool
}


