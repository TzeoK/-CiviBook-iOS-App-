import SwiftUI

struct PoiBookingFormView: View {
    @StateObject var viewModel = PoiBookingViewModel()
    let poiID: String
    @Environment(\.dismiss) private var dismiss // Handles dismissal
    @State private var showSuccessMessage = false // Controls the alert
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage? = nil
    // Define the correct order of days (Monday = 0, Sunday = 6)
    private let sortedWeekdays = [1, 2, 3, 4, 5, 6, 0] // Monday to Sunday
    
    private func sortedDays() -> [Int] {
        return viewModel.selectedDays.sorted { day1, day2 in
            sortedWeekdays.firstIndex(of: day1)! < sortedWeekdays.firstIndex(of: day2)!
        }
    }
    
    
    private var categoryTranslations: [String: String] {
        [
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
    }
    
    var body: some View {
        
        
        ZStack {
            // Adaptive background color
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Κάντε Κράτηση")
                        .font(.title2)
                        .bold()
                    
                    Text("Επιλέξτε ημερομηνίες για τον χρόνο διάρκειας της κράτησης σας. Συμβουλευτείτε το ημερολόγιο απο πάνω για να βρείτε μια περίοδο χωρίς άλλα events.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Booking Start and End Time
                    DatePicker("Αρχή Κράτησης", selection: $viewModel.eventBookingStart, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "el_GR"))
                    
                    if let error = viewModel.errors["eventBookingStart"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    DatePicker("Τέλος Κράτησης", selection: $viewModel.eventBookingEnd, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "el_GR"))
                    
                    if let error = viewModel.errors["eventBookingEnd"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    Text("Παρακάτω συμπληρώστε τα στοιχεία του event ώστε οι επισκέπτες να μπορούν να δουν όλες τις πληροφορίες.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Event Image
                    Text("Εικόνα Εκδήλωσης")
                        .font(.headline)
                    Button(action: { showImagePicker = true }) {
                        Text("Επιλέξτε Εικόνα").foregroundColor(.blue)
                    }
                    if let image = selectedUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(8)
                    }
                    Text("Τίτλος Εκδήλωσης")
                        .font(.headline)
                    // Event Details
                    TextField("Τίτλος Εκδήλωσης", text: $viewModel.eventName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if let error = viewModel.errors["eventName"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    Text("παρακαλώ καντε μια επίσημη παρουσίαση-πρόσκληση για την εκδηλωσή σας δίνοντας όλες τις πληροφορίες καθώς και τις ημερομηνίες, πρόγραμμα, είσοδο και ότι άλλο χρειάζεται να γνωρίζουν οι επισκέπτες.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("Παρουσίαση της Εκδήλωσης")
                        .font(.headline)
                    
                    TextEditor(text: $viewModel.eventDescription)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        .foregroundColor(.primary)
                    
                    if let error = viewModel.errors["eventDescription"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    Text("Κατηγορία Εκδήλωσης")
                        .font(.headline)
                    
                    Picker("Κατηγορία Εκδήλωσης", selection: $viewModel.eventCategory) {
                        Text("Επιλέξτε Κατηγορία").tag("")
                        
                        // Iterate through the dictionary instead of hardcoding categories
                        ForEach(categoryTranslations.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                            Text(value).tag(key)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if let error = viewModel.errors["eventCategory"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    
                    Text("Διάρκεια Εκδήλωσης")
                        .font(.headline)
                    // Start & End Dates
                    DatePicker("Η Εκδήλωση πραγματοποιείται από", selection: $viewModel.eventStartDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "el_GR"))
                    
                    if let error = viewModel.errors["eventStartDate"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    DatePicker("Η εκδήλωση πραγματοποιείται μέχρι", selection: $viewModel.eventEndDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "el_GR"))
                    
                    if let error = viewModel.errors["eventEndDate"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    // Recurring Days
                    Text("Εβδομαδιαίο Πρόγραμμα Εκδήλωση").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            Button(action: {
                                if viewModel.validDays.contains(index) {
                                    viewModel.toggleDay(index)
                                }
                            }) {
                                Text(viewModel.dayName(for: index))
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 40)
                                    .background(viewModel.selectedDays.contains(index) ? Color.blue : Color.gray.opacity(viewModel.validDays.contains(index) ? 1 : 0.3))
                                    .cornerRadius(8)
                            }
                            .disabled(!viewModel.validDays.contains(index))
                        }
                    }
                    if let error = viewModel.errors["selectedDays"] {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    if !viewModel.selectedDays.isEmpty {
                        Text("Η εκδήλωση πραγματοποιείται από \(viewModel.formattedDate(viewModel.eventStartDate)) έως \(viewModel.formattedDate(viewModel.eventEndDate)) τις ημέρες: \(sortedDays().map { viewModel.dayName(for: $0) }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .bold()
                    }
                    
                    
                    
                    
                    Text("Ώρα Έναρξης")
                        .font(.headline)
                    
                    DatePicker("Επιλέξτε ώρα", selection: $viewModel.eventStartTime, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "el_GR"))
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if let error = viewModel.errors["eventStartTime"] {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Text("Συμμετοχή (πχ: 12 ευρώ ή δωρεαν..)")
                        .font(.headline)
                    
                    TextField("Συμμετοχή", text: $viewModel.startingPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation) // Allows decimal & numeric input
                    
                    // Show error if exists
                    if let error = viewModel.errors["startingPrice"] {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    
                    
                    if !viewModel.serverError.isEmpty {
                        Text(viewModel.serverError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8) // Add horizontal padding
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    // Submit Button
                    Button(action: {
                        print("Submitting Booking Form with:")
                        print("Event Name: \(viewModel.eventName)")
                        print("Description: \(viewModel.eventDescription)")
                        print("Category: \(viewModel.eventCategory)")
                        print("Start Date: \(viewModel.formattedDate(viewModel.eventStartDate))")
                        print("End Date: \(viewModel.formattedDate(viewModel.eventEndDate))")
                        print("Start Time: \(viewModel.formatTime(viewModel.eventStartTime))")
                        print("Booking Start: \(viewModel.eventBookingStart)")
                        print("Booking End: \(viewModel.eventBookingEnd)")
                        print("Recurring Days: \(viewModel.selectedDays.map { viewModel.dayName(for: $0) }.joined(separator: ", "))")
                        print("Starting Price: \(viewModel.startingPrice)")
                        print("Image Included: \(viewModel.eventImage != nil ? "Yes" : "No")")
                        viewModel.eventImage = selectedUIImage?.jpegData(compressionQuality: 0.8)
                        viewModel.submitForm(poiID: poiID) {}
                        viewModel.submitForm(poiID: poiID) {
                            showSuccessMessage = true
                        }
                    }) {
                        Text(viewModel.isSubmitting ? "Αποστέλεται..." : "Αποστολή Αίτησης Κράτησης")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.isSubmitting ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isSubmitting)
                }
                .padding()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage)
            }
            .background(Color("BackgroundColor"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color("BackgroundColor"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Λάβαμε την αίτηση κράτησης σας με επιτυχία!", isPresented: $showSuccessMessage) {
            Button("OK") { dismiss() } 
        }
        
    }
}
