//
//  ProfileView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 11/2/25.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var viewModel: LoginViewModel
    @EnvironmentObject var userEventsViewModel: UserEventsViewModel
    @EnvironmentObject var trackedEventsViewModel: TrackedEventsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var eventsExpanded = false
    @State private var trackedEventsExpanded = false
    @State private var navigateToEditProfile = false
    @State private var navigateToPasswordChange = false
    @State private var navigateToEventDetail = false //state that checks if event has been fetched before navigating and triggers navigation
    @State private var selectedEvent: HomeTabEvent? = nil

    @MainActor
    func refreshProfileData() async {
        guard let user = viewModel.user else { return }
        
        // Refresh user info (simulate re-fetch from API)
        viewModel.fetchUserProfile()
        
        // Refresh user’s booked events
        userEventsViewModel.fetchUserEvents(for: String(user.id))

        // Refresh tracked events
        trackedEventsViewModel.fetchTrackedEvents()
        
        print("Profile data refreshed")
    }

    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    let profileImagePath = viewModel.user?.profile_img
                    let imageURL = profileImagePath.flatMap { URL(string: "http://192.168.1.240:8000/storage/\($0)") }
                    
                    // Profile Image
                    if let imageURL = imageURL {
                        AsyncImage(url: imageURL) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 120, height: 120)
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)
                    }
                    
                    // User Info
                    if let user = viewModel.user {
                        VStack(alignment: .center, spacing: 10) {
                            Text(user.first_name + " " + user.last_name)
                                .font(.title)
                                .bold()
                            
                            Text("Username: \(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("Email: \(user.email)")
                                .font(.subheadline)
                            
                            if let phoneNumber = user.phone_number {
                                Text("Αριθμός Τηλεφώνου: \(phoneNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Αριθμός Τηλεφώνου: δεν έχει καταχωρηθεί")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            
                            // Edit Profile Button
                                                       Button(action: {
                                                           navigateToEditProfile = true
                                                       }) {
                                                           Text("Αλλαγή στοιχείων Προφίλ")
                                                               .font(.headline)
                                                               .foregroundColor(.white)
                                                               .padding()
                                                               .frame(maxWidth: 200)
                                                               .background(Color.blue)
                                                               .cornerRadius(10)
                                                       }
                            Button(action: {
                                navigateToPasswordChange = true
                            }) {
                                Text("Αλλαγή Κωδικού Πρόσβασης")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: 200)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            
                        }
                    } else {
                        Text("Χρήστης μή συνδεδεμένος")
                            .foregroundColor(.red)
                    }
                    
                    // Logout Button
                    Button(action: {
                        viewModel.logout()
                    }) {
                        Text("Αποσύνδεση")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    // Event Section
                    VStack(spacing: 0) {
                        // Header Button for User Events
                        DisclosureGroup(isExpanded: $eventsExpanded) {
                            if let user = viewModel.user {
                                if userEventsViewModel.events.isEmpty {
                                    Text("Δεν βρέθηκαν events.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    ForEach(userEventsViewModel.events.indices, id: \.self) { index in
                                        let event = userEventsViewModel.events[index]
                                        VStack(alignment: .center, spacing: 15) {
                                            Text(event.name)
                                                .font(.title2)
                                                .bold()
                                                .multilineTextAlignment(.center)
                                            
                                            Text(event.poi.name)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                            
                                            if let startDate = event.formattedStartDate {
                                                Text("Έναρξη Κράτησης: \(startDate)")
                                                    .font(.subheadline)
                                                    .foregroundColor(colorScheme == .dark ? Color(.gray) : Color(.darkGray))
                                                    .multilineTextAlignment(.center)
                                            }
                                            
                                            if let endDate = event.formattedEndDate {
                                                Text("Τέλος Κράτησης: \(endDate)")
                                                    .font(.subheadline)
                                                    .foregroundColor(colorScheme == .dark ? Color(.gray) : Color(.darkGray))
                                                    .multilineTextAlignment(.center)
                                            }
                                            
                                            Text("Κατάσταση Κράτησης: \(event.translatedReservationStatus)")
                                                .font(.subheadline)
                                                .foregroundColor(colorScheme == .dark ? Color(.systemGray3) : Color(.darkGray))
                                                .padding(8)
                                                .background(event.reservationRequest == "accepted" ? Color.green :
                                                                event.reservationRequest == "declined" ? Color.red : Color(red: 255/255, green: 220/255, blue: 120/255))
                                                .cornerRadius(10)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, minHeight: 180)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(red: 0.97, green: 0.97, blue: 0.97))
                                        
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                    }
                                }
                            }
                        } label: {
                            Text("Αιτήσεις Κρατήσης")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 20)
                        
                        // Tracked Events Section
                        DisclosureGroup(isExpanded: $trackedEventsExpanded) {
                            if trackedEventsViewModel.trackedEvents.isEmpty {
                                Text("Δεν βρέθηκαν events που ακολουθείτε.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(trackedEventsViewModel.trackedEvents) { event in
                                    VStack(alignment: .center, spacing: 15) {
                                        Text(event.name)
                                            .font(.title2)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                        
                                        Text("Τοποθεσία: \(event.poi_name)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                        
                                        if let startDate = event.formattedStartDate {
                                            Text("Ημερομηνία Έναρξης: \(startDate)")
                                                .font(.subheadline)
                                                .foregroundColor(colorScheme == .dark ? Color(.gray) : Color(.darkGray))
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 180)
                                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(red: 0.97, green: 0.97, blue: 0.97))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .onTapGesture {
                                        print("Fetching event details for ID: \(event.id)...")

                                        homeViewModel.fetchEventDetails(eventId: event.id) { fetchedEvent in
                                            DispatchQueue.main.async {
                                                if let fetchedEvent = fetchedEvent {
                                                    print("Event details fetched: \(fetchedEvent.name)")
                                                    self.selectedEvent = fetchedEvent
                                                    self.navigateToEventDetail = true
                                                    print("navigateToEventDetail set to: \(self.navigateToEventDetail)")
                                                } else {
                                                    print("Failed to fetch event details.")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("Εκδηλώσεις με ενημέρωση mail")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .multilineTextAlignment(.center)
                        }
                        
                    }
                    .padding(.all, 15)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(15)
                    
                    Spacer()
                }
                .background(Color("BackgroundColor"))
                .padding()
                .navigationTitle("Προφίλ")
                .navigationBarTitleDisplayMode(.inline)
            }
            .refreshable {
                print("Refreshing Profile Data...")
                    Task {
                        viewModel.fetchUserProfile()  // Get latest user info
                        userEventsViewModel.fetchUserEvents(for: String(viewModel.user?.id ?? 0))  // Refetch bookings
                        trackedEventsViewModel.fetchTrackedEvents()  // Update tracked events
                    }
            }
            .navigationDestination(isPresented: $navigateToEventDetail) {
                if let event = selectedEvent {
                    EventDetailsView(event: event)
                }
            }
            .navigationDestination(isPresented: $navigateToEditProfile) {
                if let user = viewModel.user {
                    EditProfileView(user: user) // Pass the user object
                }
            }
            .navigationDestination(isPresented: $navigateToPasswordChange) {
                    ChangePasswordView()
            }



            
        }
        .onAppear {
            if let user = viewModel.user {
                userEventsViewModel.fetchUserEvents(for: String(user.id)) // Fetch events on view appearance
                trackedEventsViewModel.fetchTrackedEvents()
            }
        }
        .background(Color("BackgroundColor"))
    }
}
