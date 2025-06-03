import SwiftUI

struct HomeView: View {
    @State private var selectedUserProfile: Bool = false
    @EnvironmentObject var viewModel: LoginViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject private var userEventsViewModel = UserEventsViewModel()
    @StateObject private var trackedEventsViewModel = TrackedEventsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0 // Track the active tab
    @State private var selectedCategory: EventCategory = .thisWeek
    @State private var maxCardHeight: CGFloat = 400
    
    @MainActor
    func refreshEvents() async {
        userEventsViewModel.fetchUserEvents(for: String(viewModel.user?.id ?? 0))
        homeViewModel.fetchDailyEvents()
        homeViewModel.fetchWeeklyEvents()
        homeViewModel.fetchMonthlyEvents()
        homeViewModel.fetchNextMonthEvents()
        print("refresh called")
    }
    
    func refreshPoi() async {
        homeViewModel.fetchPOIs()
    }
    
    
    
    
    
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .edgesIgnoringSafeArea(.all)
                TabView(selection: $selectedTab) {
                    // Home Tab
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 0) {
                                
                                ZStack {
                                    Color("BackgroundColor")
                                        .edgesIgnoringSafeArea(.all)
                                    
                                    VStack(alignment: .center, spacing: 8) {
                                        // CiviBook Title
                                        Text("CiviBook")
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                        
                                        
                                        
                                        Text("Βρές τον χώρο για την εκδήλωσή σου εύκολα και γρήγορα!")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                            .padding(12)
                                            .frame(maxWidth: min(geometry.size.width * 0.8, 320))
                                            .background(colorScheme == .dark ? Color(red: 100/255, green: 160/255, blue: 240/255) :
                                                            Color(red: 126/255, green: 178/255, blue: 250/255))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(radius: 5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 30)
                                }
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(Color("BackgroundColor"))
                                
                                // Hero Section
                                VStack(spacing: 0) {
                                    Image(colorScheme == .dark ? "art" : "art")
                                        .resizable()
                                        .scaledToFit() // Keeps full image visible, no cropping
                                        .frame(maxWidth: .infinity) // Expands to full width
                                    
                                    VStack(spacing: 7) {
                                        Text("Event Hosting με το πάτημα ενός κουμπιού.")
                                            .font(.title2)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.primary)
                                        
                                        Text("Επίλεξε τον χώρο που σου ταιριάζει και οργάνωσε το event σου. Άσε σε εμάς τα υπόλοιπα!")
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                        
                                        Button(action: { selectedTab = 1 }) {
                                            Text("Κάνε Κράτηση")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .frame(maxWidth: 200)
                                                .background(Color.blue)
                                                .cornerRadius(10)
                                        }
                                        .padding(.top, 10)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.secondarySystemBackground)) // Separate readable section
                                    .cornerRadius(15)
                                }
                                .frame(maxWidth: .infinity, minHeight: 350)
                                
                                // Event Selection Buttons (Picker)
                                Picker("Select Events", selection: $selectedCategory) {
                                    ForEach([EventCategory.today, EventCategory.thisWeek, EventCategory.thisMonth, EventCategory.nextMonth], id: \.self) { category in
                                        Text(category.displayName)
                                            .lineLimit(1) // Ensures text remains on one line
                                            .minimumScaleFactor(0.4) // Shrinks text if needed
                                            .frame(maxWidth: .infinity) // Spreads text evenly
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal)
                                .padding(.top, 20)
                                
                                
                                
                                if filteredEvents.isEmpty {
                                    Text("Δεν υπάρχουν εκδηλώσεις σε αυτήν την κατηγορία.")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 15) {
                                        if filteredEvents.isEmpty {
                                            Text("Δεν υπάρχουν εκδηλώσεις σε αυτήν την κατηγορία.")
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                                .padding()
                                        } else {
                                            ForEach(filteredEvents) { event in
                                                EventCard(event: event) { likedEvent in
                                                    homeViewModel.toggleLike(for: likedEvent)
                                                }
                                                .padding(.horizontal, 20)
                                                
                                            }
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            
                                VStack {
                                    Text("Home Screen Content")
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, minHeight: geometry.size.height - 350)
                            }
                        }
                        .background(Color("BackgroundColor"))
                        .refreshable {
                            print("🔄 Refreshing Data...")
                            await refreshEvents()
                            await refreshPoi()
                        }
                    }
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                    
                    
                    // Bookings Tab
                    BookingsTabView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Κρατήσεις")
                        }
                        .tag(1)
                    
                    // Calendar Tab
                    CalendarTabView()
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("Ημερολόγιο")
                        }
                        .tag(2)

                    
                    // Events Tab
                    EventTabView()
                        .tabItem {
                            Image(systemName: "star.fill")
                            Text("Εκδηλώσεις")
                        }
                        .environmentObject(homeViewModel)
                        .tag(3)

                    
                    // Notifications Tab
                    NotificationsView()
                        .tabItem {
                            Image(systemName: "bell.fill")
                            Text("Ειδοποιήσεις")
                        }
                        .environmentObject(homeViewModel)
                        .badge(homeViewModel.unreadCount) // Show unread count badge
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundColor"))
                        .tag(4)
                }.onChange(of: selectedTab) { _, newTab in
                    Task {
                        if newTab == 0 {  // Home tab
                            print("🏠 Home tab selected, refreshing events...")
                            await refreshEvents()
                        } else if newTab == 1 {  // Bookings tab
                            print("📍 Bookings tab selected, refreshing POIs...")
                            await refreshPoi()
                        }
                    }
                }
                .onAppear {
                    Task {
                        await refreshEvents() // refetch events when returning to HomeView
                    }
                }
                
                
                
                
                // Profile Button (Navigates to ProfileView)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedUserProfile = true // Trigger navigation
                        }) {
                            if let profileImagePath = viewModel.user?.profile_img,
                               let imageURL = URL(string: "http://192.168.1.240:8000/storage/\(profileImagePath)") {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 10)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .padding(10)
                                    .background(Circle().fill(Color.blue))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $selectedUserProfile) {
                ProfileView()
                    .environmentObject(homeViewModel)
                    .environmentObject(userEventsViewModel)
                    .environmentObject(trackedEventsViewModel)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var filteredEvents: [HomeTabEvent] {
        let events: [HomeTabEvent]
        switch selectedCategory {
        case .today:
            events = homeViewModel.todayEvents
        case .thisWeek:
            events = homeViewModel.thisWeekEvents
        case .thisMonth:
            events = homeViewModel.thisMonthEvents
        case .nextMonth:
            events = homeViewModel.nextMonthEvents
        }
        
        print("🧐 Showing \(events.count) events for category: \(selectedCategory)")
        return events
    }
}






#Preview {
    HomeView().environmentObject(HomeViewModel())
        .environmentObject(LoginViewModel())
}


// Event Category Enum
enum EventCategory {
    case today, thisWeek, thisMonth, nextMonth
    
    var displayName: String {
        switch self {
        case .today: return "Σήμερα"
        case .thisWeek: return "Eβδομάδα"
        case .thisMonth: return "Mήνας"
        case .nextMonth: return "Επόμ. Μήνας"
        }
    }
}




