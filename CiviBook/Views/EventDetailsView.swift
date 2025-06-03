//
//  EventDetailsView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 8/2/25.
//

import SwiftUI

struct EventDetailsView: View {
    @ObservedObject var event: HomeTabEvent
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 15) {
                Text("📆: \(formattedEventDate(event: event))")
                // Event Image
                if let imgPath = event.imgPath, let imageURL = URL(string: "http://192.168.1.240:8000/storage/\(imgPath)") {
                    AsyncImage(url: imageURL) { image in
                        image.resizable()
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.9, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ProgressView()
                            .frame(width: UIScreen.main.bounds.width * 0.9, height: 250)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .frame(maxWidth: .infinity)
                }
                
                
                
                // Event Name
                Text(event.name)
                    .font(.title)
                    .bold()
                
                // Category
                Text("Κατηγορία: \(translateCategory(event.category))")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                // Description
                Text("📖 Περιγραφή")
                    .font(.headline)
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                
                
                // Date & Time
                VStack(alignment: .center, spacing: 8) {
                    // Recurrence
                    VStack {
                        Text("Πρόγραμμα:")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text(getRecurrenceDescription(event: event))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 5)
                    Text("Ώρα Έναρξης: \(event.eventStartTime ?? "Άγνωστη")")
                        .padding(.bottom,5)
                    Text("Συμμετοχή: \(event.entryCost ?? "Δωρεάν")")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                
                
                // Location
                VStack(alignment: .center, spacing: 8) {
                    
                    
                    Text("Τοποθεσία: \(event.poi.name)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Διεύθυνση: \(event.poi.display_address ?? "δεν βρέθηκε διεύθυνση")")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Google Maps Button
                    Button(action: {
                        let latitude = Double(event.poi.latitude)
                        let longitude = Double(event.poi.longitude)
                        redirectToGoogleMaps(latitude: latitude, longitude: longitude, placeName: event.poi.name, address: event.poi.display_address)
                    }) {
                        HStack {
                            Image(systemName: "map")
                                .font(.headline)
                            Text("Εύρεση στο Google Maps")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                
                
                
                
                // Like Button
                HStack {
                    Button(action: {
                        homeViewModel.toggleLike(for: event)
                    }) {
                        Image(systemName: event.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(event.isLiked ? .red : .gray)
                            .font(.title2)
                    }
                    Text("\(event.likes) \(event.likes == 1 ? "Like" : "Likes")")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
                .padding(.top, 10)
                
                Text("Θέλετε να ενημερωθείτε μέσω email μία μέρα πρίν ξεκινήσει η εκδήλωση")
                .padding(.top, 10)
                // Tracking Button
                Button(action: {
                    if homeViewModel.isTracked {
                        homeViewModel.untrackEvent(eventId: event.id)
                    } else {
                        homeViewModel.trackEvent(eventId: event.id)
                    }
                }) {
                    
                    Text(homeViewModel.isTracked ? "Να μήν ενημερωθώ" : "Να ενημερωθώ")
                        .font(.title2)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(homeViewModel.isTracked ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 5)
                
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            
        }
        .onAppear {
            homeViewModel.checkIfTracked(eventId: event.id)
        }
        .navigationTitle("Λεπτομέρειες Εκδήλωσης")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
    }
    
    
    
    
    
    // 📌 Helper Functions
    private func translateCategory(_ category: String) -> String {
        let translations = [
            "Arts": "Τέχνες", "Culture": "Πολιτισμός", "Entertainment": "Διασκέδαση",
            "Fitness": "Φυσική Κατάσταση & Ευεξία", "Health": "Υγεία",
            "Environment": "Περιβάλλον", "Business": "Επιχειρήσεις",
            "Technology": "Τεχνολογία", "Community": "Κοινότητα",
            "Civil": "Κοινωνικές Υποθέσεις", "Food": "Φαγητό & Εστίαση",
            "Miscellaneous": "Διάφορα"
        ]
        return translations[category] ?? category
    }
    
    private func getRecurrenceDescription(event: HomeTabEvent) -> String {
        if event.recurringDays.isEmpty {
            return "Δεν υπάρχει πρόγραμμα διαθέσιμο"
        }
        
        let daysOfWeek = ["Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο", "Κυριακή"]
        let originalOrder = ["Κυριακή", "Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "el_GR")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.isLenient = true
        
        guard let startDate = dateFormatter.date(from: event.eventStartDate),
              let endDate = dateFormatter.date(from: event.eventEndDate) else {
            return "Ημερομηνίες δεν είναι διαθέσιμες"
        }
        
        // If the event lasts only one day, print just the date
        if startDate == endDate {
            dateFormatter.dateFormat = "dd-MM-yyyy"
            return dateFormatter.string(from: startDate)
        }
        
        let durationInDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        var selectedDates: [(day: String, date: String)] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = Calendar.current.component(.weekday, from: currentDate) - 1
            if event.recurringDays.contains(weekday) {
                dateFormatter.dateFormat = "dd-MM-yyyy"
                let formattedDate = dateFormatter.string(from: currentDate)
                let dayName = originalOrder[weekday] // Use default order
                selectedDates.append((day: dayName, date: formattedDate))
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        dateFormatter.dateFormat = "dd-M-yyyy"
        let eventStartDateFormatted = dateFormatter.string(from: startDate)
        let eventEndDateFormatted = dateFormatter.string(from: endDate)
        
        // If event lasts more than 7 days
        if durationInDays > 7 {
            if Set(event.recurringDays) == Set(0...6) {
                return """
                Από \(eventStartDateFormatted) μέχρι \(eventEndDateFormatted), καθημερινά
                """
            } else {
                let uniqueDays = Array(Set(selectedDates.map { $0.day }))
                    .sorted { daysOfWeek.firstIndex(of: $0)! < daysOfWeek.firstIndex(of: $1)! } // Sort in Monday-first order
                
                return """
                Από \(eventStartDateFormatted) μέχρι \(eventEndDateFormatted), κάθε \(uniqueDays.joined(separator: ", "))
                
                \(selectedDates
                    .sorted { $0.date < $1.date }
                    .map { "\($0.day) \($0.date)" }
                    .joined(separator: "\n"))
                """
            }
        }
        
        // If event lasts ≤ 7 days:
        //    - If all days in range are in recurringDays -> "καθημερινά"
        //    - Otherwise, list the exact dates instead of "κάθε"
        if selectedDates.count == durationInDays + 1 {
            return """
               Από \(eventStartDateFormatted) μέχρι \(eventEndDateFormatted), καθημερινά

               \(selectedDates
                   .sorted { $0.date < $1.date }  // sort by date only, no special day sorting
                   .map { "\($0.day) \($0.date)" }
                   .joined(separator: "\n"))
               """
        } else {
            return selectedDates
                .sorted { daysOfWeek.firstIndex(of: $0.day) ?? 7 < daysOfWeek.firstIndex(of: $1.day) ?? 7 } // Force Monday-first sorting
                .map { "\($0.day) \($0.date)" }
                .joined(separator: "\n")
        }
    }
    
    
    
    
    
    private func redirectToGoogleMaps(latitude: Double?, longitude: Double?, placeName: String?, address: String?) {
        var baseUrl = "https://www.google.com/maps/search/?api=1"
        
        if let placeName = placeName, let address = address, !placeName.isEmpty, !address.isEmpty {
            let encodedQuery = "\(placeName), \(address)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            baseUrl += "&query=\(encodedQuery)"
        } else if let lat = latitude, let lon = longitude {
            baseUrl += "&query=\(lat),\(lon)"
        } else {
            print("❌ Error: Missing location data.")
            return
        }
        
        if let url = URL(string: baseUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    
    private func formattedEventDate(event: HomeTabEvent) -> String {
        let startDate = formatDate(event.eventStartDate)
        let endDate = formatDate(event.eventEndDate)
        return startDate == endDate ? startDate : "\(startDate) - \(endDate)"
    }
    
    private func formatDate(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dateObj = formatter.date(from: date) else { return date }
        formatter.locale = Locale(identifier: "el_GR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: dateObj)
    }
}
