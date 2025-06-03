import Foundation
import Combine

class PoiBookingViewModel: ObservableObject {
    // Form fields
    @Published var validDays: [Int] = []
    @Published var eventName = ""
    @Published var eventDescription = ""
    @Published var eventCategory = ""
    @Published var eventBookingStart = Date()
    @Published var eventBookingEnd = Date()
    @Published var eventStartDate = Date() {
        didSet {
            recalculateValidDays()
        }
    }
    @Published var eventEndDate = Date() {
        didSet {
            recalculateValidDays()
        }
    }
    @Published var eventStartTime = Date()
    @Published var startingPrice = ""
    @Published var selectedDays: [Int] = []
    @Published var eventImage: Data? = nil

    // Error handling
    @Published var errors: [String: String] = [:]
    @Published var serverError = ""
    @Published var successMessage = ""
    @Published var isSubmitting = false

    let categoryChoices = [
        "Arts", "Culture", "Entertainment", "Fitness & Wellness",
        "Health", "Environment", "Business", "Technology",
        "Community", "Civil Affairs", "Food & Dining", "Miscellaneous"
    ]

    init() {
           recalculateValidDays()  // Ensure validDays is populated on initialization
       }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    func dayName(for index: Int) -> String {
        let days = ["Κυριακή", "Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο"]
        return days[index]
    }

    func toggleDay(_ index: Int) {
        if selectedDays.contains(index) {
            selectedDays.removeAll { $0 == index }
        } else {
            selectedDays.append(index)
        }
    }
    
    func recalculateValidDays() {
        guard eventStartDate <= eventEndDate else {
            validDays = []
            return
        }

        let calendar = Calendar.current

        // Ensure dates are normalized to midnight and are set before user interacts with ui to avoid the case of one of them being uninitialized
        let startDate = calendar.startOfDay(for: eventStartDate)//startofday removes time component by making it 0000
        let endDate = calendar.startOfDay(for: eventEndDate)//again startofday removes time difference by setting it to 0000

        var daysSet = Set<Int>()//this collects days in the selected range
        var currentDate = startDate

        //iterate over each date till end date
        while currentDate <= endDate {
            let dayOfWeek = calendar.component(.weekday, from: currentDate) - 1 // Monday=0, Sunday=6 (1-7 indexed sunday->monday->etc .... -1 subtraction to make it go 0-6)
            daysSet.insert(dayOfWeek)//insert the index of this weekday into array
            
            // Prevent unnecessary extra loop iteration for same-day events for a bug fix
            if startDate == endDate { break }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        validDays = Array(daysSet).sorted()

        // Ensure selectedDays only contains valid days
        selectedDays.removeAll { !validDays.contains($0) }
    }

    
    // MARK: - Validation
    func validateForm() -> Bool {
        var newErrors: [String: String] = [:]

        // Name validation
        if eventName.isEmpty {
            newErrors["eventName"] = "Το όνομα της εκδήλωσης είναι υποχρεωτικό."
        }

        // Description validation
        if eventDescription.isEmpty {
            newErrors["eventDescription"] = "Η περιγραφή της εκδήλωσης είναι υποχρεωτική."
        }

        // Category validation
        if eventCategory.isEmpty {
            newErrors["eventCategory"] = "Η κατηγορία της εκδήλωσης είναι υποχρεωτική."
        }

        // booking start and end time validation
        if eventBookingStart >= eventBookingEnd {
            newErrors["eventBookingEnd"] = "Το τέλος της κράτησης πρέπει να είναι μετά την αρχή της κράτησης. Αν επιθυμείτε μονοήμερη κράτηση αλλάξτε την ώρα τέλους κράτησης για αργότερα."
        }

        // ensures event dates fall between the booking range or are the same
        if !(eventBookingStart...eventBookingEnd).contains(eventStartDate) ||
           !(eventBookingStart...eventBookingEnd).contains(eventEndDate) {
            newErrors["eventStartDate"] = "Η ημερομηνία έναρξης της εκδήλωσης πρέπει να είναι εντός της κράτησης."
            newErrors["eventEndDate"] = "Η ημερομηνία τέλους της εκδήλωσης πρέπει να είναι εντός της κράτησης."
        }
        
        // start and end date validation
        if eventStartDate > eventEndDate {
            newErrors["eventEndDate"] = "Η ημερομηνία τέλους της εκδήλωσης πρέπει να είναι μετά την ημερομηνία έναρξης."
        }

        // recurring days validation
        if selectedDays.isEmpty {
            newErrors["selectedDays"] = "Παρακαλώ επιλέξτε τουλάχιστον μία ημέρα για το εβδομαδιαίο πρόγραμμα."
        }

        // price validation
        if startingPrice.isEmpty {
            newErrors["startingPrice"] = "Είναι υποχρεωτικό να αναφέρετε το κόστος εισόδου ή να γράψετε δωρεάν."
        }

        self.errors = newErrors
        return newErrors.isEmpty
    }

    // MARK: - Submit Form
    func submitForm(poiID: String, onSuccess: @escaping () -> Void) {
        // Clear errors before validating
        self.errors = [:]
        self.serverError = ""

        guard validateForm() else {
            self.serverError = "Η φόρμα περιέχει σφάλματα. Παρακαλώ ελέγξτε τα πεδία σας."
            return
        }

        isSubmitting = true
        successMessage = ""

        // Get the token from storage
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            self.serverError = "Το διακριτικό αυθεντικοποίησης λείπει. Παρακαλώ συνδεθείτε ξανά."
            isSubmitting = false
            return
        }

        let url = URL(string: "http://192.168.1.240:8000/api/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()

        func addField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Formatters
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Add form data fields
        addField(name: "name", value: eventName)
        addField(name: "description", value: eventDescription)
        addField(name: "category", value: eventCategory)
        addField(name: "event_start", value: isoFormatter.string(from: eventBookingStart))
        addField(name: "event_end", value: isoFormatter.string(from: eventBookingEnd))
        addField(name: "event_start_date", value: dateFormatter.string(from: eventStartDate))
        addField(name: "event_end_date", value: dateFormatter.string(from: eventEndDate))
        addField(name: "event_start_time", value: formatTime(eventStartTime))
        addField(name: "entry_cost", value: startingPrice)
        addField(name: "recurring_days", value: String(data: try! JSONEncoder().encode(selectedDays), encoding: .utf8)!)
        addField(name: "poi_id", value: poiID)

        // Add image data
        if let imageData = eventImage {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"img_path\"; filename=\"event.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSubmitting = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.serverError = "Αποτυχία υποβολής φόρμας: \(error.localizedDescription)"
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    self.serverError = "Δεν υπάρχει απόκριση από τον διακομιστή."
                }
                return
            }

            if httpResponse.statusCode == 201 {
                do {
                    let decodedResponse = try JSONDecoder().decode(EventResponse.self, from: data)
                    if decodedResponse.success {
                        DispatchQueue.main.async {
                            self.successMessage = decodedResponse.message
                            onSuccess()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.serverError = decodedResponse.message
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.serverError = "Αποτυχία ανάλυσης μηνύματος επιτυχίας."
                    }
                }
            } else if httpResponse.statusCode == 422 {
                do {
                    let decodedResponse = try JSONDecoder().decode([String: [String]].self, from: data)
                    DispatchQueue.main.async {
                        self.errors = decodedResponse.mapValues { $0.joined(separator: ", ") }
                        self.serverError = "Παρουσιάστηκαν σφάλματα επικύρωσης. Ελέγξτε τα δεδομένα σας."
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.serverError = "Η επικύρωση απέτυχε"
                    }
                }
            } else if httpResponse.statusCode == 409 {
                do {
                    let decodedResponse = try JSONDecoder().decode(EventResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.serverError = decodedResponse.message
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.serverError = "Παρουσιάστηκε σύγκρουση αλλά το μήνυμα λάθους απέτυχε να μεταφραστεί"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.serverError = "Απρόβλεπτο σφάλμα. Δοκιμάστε ξανά."
                }
            }
        }.resume()
    }

    // MARK: - Helper Functions
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct EventResponse: Decodable {
    let success: Bool
    let message: String
    let data: EventData?
}

struct EventData: Decodable {
    let id: Int
    let name: String
    let description: String
    let category: String
    let event_start: String
    let event_end: String
}
