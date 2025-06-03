//
//  EventCard.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 3/2/25.
//

import SwiftUI

struct EventCard: View {
    @ObservedObject var event: HomeTabEvent
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme
 
    
    let onLikeToggle: (HomeTabEvent) -> Void
    
    init(event: HomeTabEvent, onLikeToggle: @escaping (HomeTabEvent) -> Void) {
            self.event = event
            self.onLikeToggle = onLikeToggle
        }
    
    var body: some View {
        return NavigationLink(destination: EventDetailsView(event: event)) {
            VStack(alignment: .leading, spacing: 12) {
                // Event Date Badge
                Text(formattedDateRange(event: event))
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                // Event Image
                if let imageUrl = URL(string: "http://192.168.1.240:8000/storage/" + (event.imgPath ?? "uploads/event_images/event-default.png")) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                }
                
                // Event Details
                VStack(alignment: .center, spacing: 6) {
                                    Text(event.name)
                                        .font(.headline)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Κατηγορία: \(translateCategory(event.category))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Τοποθεσία: \(event.poi.name)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                    

                
                Divider()
                    .frame(height: 1) // Thickness
                    .background(Color.gray.opacity(0.5)) // Line color
                    .padding(.vertical, 5)
                
                HStack {
                    Button(action: {
                        print("Before Toggle: \(event.isLiked)") // 🔍 Debugging Log
                        // Call API from HomeViewModel
                        homeViewModel.toggleLike(for: event)
                        
                    }) {
                        Image(systemName: event.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(event.isLiked ? .red : .gray)
                            .font(.title2)
                    }
                    
                    Text("\(event.likes) \(event.likes == 1 ? "Like" : "Likes")")
                        .foregroundColor(.primary)

                }
                
            }
            .padding(20)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            
        }
        
        
        // Helper Functions
        func formattedDateRange(event: HomeTabEvent) -> String {
            let startDate = formatDate(event.eventStartDate)
            let endDate = formatDate(event.eventEndDate)
            return startDate == endDate ? startDate : "\(startDate) - \(endDate)"
        }
        
        func formatDate(_ date: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let dateObj = formatter.date(from: date) else { return date }
            formatter.locale = Locale(identifier: "el_GR")
            formatter.dateFormat = "d MMM"
            return formatter.string(from: dateObj)
        }
        
        func formatTime(_ time: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            guard let dateObj = formatter.date(from: time) else { return time }
            formatter.locale = Locale(identifier: "el_GR")
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: dateObj)
        }
        
        func translateCategory(_ category: String) -> String {
            let CATEGORY_TRANSLATIONS = [
                "Arts": "Τέχνες",
                "Culture": "Πολιτισμός",
                "Entertainment": "Διασκέδαση",
                "Fitness": "Φυσική Κατάσταση & Ευεξία",
                "Health": "Υγεία",
                "Environment": "Περιβάλλον",
                "Business": "Επιχειρήσεις",
                "Technology": "Τεχνολογία",
                "Community": "Κοινότητα",
                "Civil": "Κοινωνικές Υποθέσεις",
                "Food": "Φαγητό & Εστίαση",
                "Miscellaneous": "Διάφορα"
            ]
            return CATEGORY_TRANSLATIONS[category] ?? category
        }
        
        func getRecurrenceDescription(event: HomeTabEvent) -> String {
            // Check if the recurringDays array is empty
            if event.recurringDays.isEmpty {
                return "Δεν υπάρχει πρόγραμμα διαθέσιμο"
            }
            
            let daysOfWeek = ["Κυριακή", "Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο"]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd" // Adjust this to match your input date format
            dateFormatter.locale = Locale(identifier: "el_GR")
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.isLenient = true
            
            guard let startDate = dateFormatter.date(from: event.eventStartDate),
                  let endDate = dateFormatter.date(from: event.eventEndDate) else {
                return "Ημερομηνίες δεν είναι διαθέσιμες"
            }
            
            let durationInDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
            
            if durationInDays == 1 {
                dateFormatter.dateFormat = "EEEE dd-M-yyyy"
                let formattedDate = dateFormatter.string(from: startDate)
                return formattedDate
            }
            
            if durationInDays <= 7 {
                var eventDates: [(day: String, date: String)] = []
                
                for day in event.recurringDays {
                    var currentDate = startDate
                    while currentDate <= endDate {
                        if Calendar.current.component(.weekday, from: currentDate) == day + 1 {
                            dateFormatter.dateFormat = "dd-M-yyyy"
                            let formattedDate = dateFormatter.string(from: currentDate)
                            eventDates.append((day: daysOfWeek[day], date: formattedDate))
                            break
                        }
                        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
                    }
                }
                
                if eventDates.isEmpty {
                    return "Δεν υπάρχει πρόγραμμα διαθέσιμο"
                }
                
                eventDates.sort { $0.date < $1.date }
                let sortedEventDates = eventDates.map { "\($0.day) \($0.date)" }.joined(separator: ", ")
                return sortedEventDates
            }
            
            if durationInDays > 7 {
                let sortedDays = event.recurringDays.sorted()
                
                if sortedDays.count == 7 {
                    dateFormatter.dateFormat = "dd-M-yyyy"
                    let eventStartDateFormatted = dateFormatter.string(from: startDate)
                    let eventEndDateFormatted = dateFormatter.string(from: endDate)
                    return "Από \(eventStartDateFormatted) μέχρι \(eventEndDateFormatted), καθημερινά"
                }
                
                let sundayIndex = sortedDays.firstIndex(of: 0)
                var adjustedDays = sortedDays
                if let sundayIndex = sundayIndex {
                    adjustedDays.remove(at: sundayIndex)
                    adjustedDays.append(0)
                }
                
                let selectedDays = adjustedDays.map { daysOfWeek[$0] }.joined(separator: ", ")
                dateFormatter.dateFormat = "dd-M-yyyy"
                let eventStartDateFormatted = dateFormatter.string(from: startDate)
                let eventEndDateFormatted = dateFormatter.string(from: endDate)
                return "Από \(eventStartDateFormatted) μέχρι \(eventEndDateFormatted), κάθε \(selectedDays)"
            }
            
            return "Δεν υπάρχει πρόγραμμα διαθέσιμο"
        }
    }
}
