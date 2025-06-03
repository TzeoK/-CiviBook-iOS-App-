import SwiftUI
import FSCalendar

struct PoiDetailsView: View {
    @StateObject private var poiDetailsViewModel = PoiDetailsViewModel()
    @StateObject private var bookingViewModel = PoiBookingViewModel()
    @State private var selectedEventName: String? = nil
    @State private var showBookingForm = false
    let poi: POI // Assuming POI is the model you're using
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // POI Image
                if let poiImg = poi.poi_img, !poiImg.isEmpty,
                   let imageURL = URL(string: "http://192.168.1.240:8000/storage/\(poiImg)") {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                // POI Name
                Text(poi.name)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                // POI Address
                Text(poi.display_address ?? "δεν βρέθηκε διεύθυνση")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // POI Description
                Text(poi.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                // Google Maps Redirect Button
                Button(action: {
                    let latitude = Double(poi.latitude)
                    let longitude = Double(poi.longitude)
                    redirectToGoogleMaps(latitude: latitude, longitude: longitude, placeName: poi.name, address: poi.display_address)
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

                
                // Calendar Section
                Text("Ημερολόγιο Κρατήσεων")
                    .font(.headline)
                    .padding(.top, 16)
                
                Text("Χρησιμοποιήστε το παρακάτω ημερολόγιο για να δείτε ποιές μέρες είναι διαθέσιμες. Οι μέρες που είναι μαρκαρισμένες κόκκινες είναι δεσμευμένες για κάποια άλλη Κράτηση. Το διάστημα που θα επιλέξετε παρακάτω για την αίτηση κράτησης για το Event σας θα πρέπει να είναι κενό εντελώς χωρίς καμία ημέρα μαρκαρισμένη ως κόκκινη.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if poiDetailsViewModel.isLoading {
                    ProgressView("Φόρτωση Κρατήσεων...")
                } else if let error = poiDetailsViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    FSCalendarWrapper(
                        events: poiDetailsViewModel.calendarEvents,
                        onDateSelected: { eventName in
                            selectedEventName = eventName 
                        }
                    )
                    .frame(height: 300)
                }
                if let eventName = selectedEventName {
                    Text("Η επιλεγμένη ημέρα είναι δεσμευμένη για το event: \(eventName)")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                } else {
                    Text("Η επιλεγμένη ημέρα είναι ελεύθερη προς δέσμευση.")
                        .font(.body)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
                
                // Toggle Booking Form Button
                Button(action: {
                    withAnimation {
                        showBookingForm.toggle()
                    }
                }) {
                    Text(showBookingForm ? "Απόκρυψη Φόρμας Κράτησης" : "Εμφάνιση Φόρμας Κράτησης")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(showBookingForm ? Color.red : Color.green)
                        .cornerRadius(10)
                }
                
                // Booking Form
                if showBookingForm {
                    PoiBookingFormView(poiID: String(poi.id))
                        .transition(.slide)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            .navigationTitle("Λεπτομέρεις Τοποθεσίας")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await poiDetailsViewModel.fetchEvents(for: poi.id)
                }
            }
        }
        .background(Color("BackgroundColor"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
            Task {
                await poiDetailsViewModel.fetchEvents(for: poi.id)
            }
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

}


