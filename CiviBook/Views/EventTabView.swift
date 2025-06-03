//
//  EventTab.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

import SwiftUI

struct EventTabView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                // Filters Section
                VStack(alignment: .leading, spacing: 2) {
                    
                    // POI Selection
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Επιλέξτε τοποθεσία εκδήλωσης:")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Picker("Τοποθεσία", selection: $eventViewModel.selectedPOI) {
                            Text("Όλες").tag(nil as Int?)
                            ForEach(eventViewModel.pois) { poi in
                                Text(poi.name).tag(poi.id as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: eventViewModel.selectedPOI) {
                            eventViewModel.applyFilters()
                        }
                        
                    }
                    .padding(.horizontal)

                    // Category Selection
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Επιλέξτε κατηγορία εκδήλωσης:")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Picker("Κατηγορία", selection: $eventViewModel.selectedCategory) {
                            Text("Όλες").tag(nil as String?)
                            Text("Τέχνες").tag("Arts" as String?)
                            Text("Πολιτισμός").tag("Culture" as String?)
                            Text("Διασκέδαση").tag("Entertainment" as String?)
                            Text("Υγεία").tag("Health" as String?)
                            Text("Περιβάλλον").tag("Environment" as String?)
                            Text("Επιχειρήσεις").tag("Business" as String?)
                            Text("Τεχνολογία").tag("Technology" as String?)
                            Text("Κοινότητα").tag("Community" as String?)
                            Text("Φαγητό").tag("Food" as String?)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: eventViewModel.selectedCategory) {
                            eventViewModel.applyFilters()
                        }
                    }
                    .padding(.horizontal)

                    // Search Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Αναζήτηση με βάση το όνομα:")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        TextField("🔍 Αναζήτηση εκδηλώσεων...", text: $eventViewModel.searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onReceive(eventViewModel.$searchQuery.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { _ in
                                eventViewModel.applyFilters()
                            }
                    }
                    .padding(.horizontal)

                    // Date Pickers
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Επιλέξτε ημερομηνίες Ενδιαφέροντος:")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 10) {
                            VStack(alignment: .leading) {
                                Text("Από:")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: Binding(
                                    get: { eventViewModel.startDate ?? Date() },
                                    set: { eventViewModel.startDate = $0; eventViewModel.fetchFilteredEvents() }
                                ), displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .environment(\.locale, Locale(identifier: "el_GR"))
                            }

                            VStack(alignment: .leading) {
                                Text("Έως:")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                DatePicker("", selection: Binding(
                                    get: { eventViewModel.endDate ?? Date() },
                                    set: { eventViewModel.endDate = $0; eventViewModel.fetchFilteredEvents() }
                                ), displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .environment(\.locale, Locale(identifier: "el_GR"))
                            }
                        }
                    }
                    .padding(.horizontal)

                } // End of Filters Section
                .padding(.top, 10)

                // Event List
                if eventViewModel.events.isEmpty {
                    Text("Δεν υπάρχουν εκδηλώσεις")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(eventViewModel.events) { event in
                                EventCard(event: event, onLikeToggle: { likedEvent in
                                    eventViewModel.fetchFilteredEvents()
                                })
                                .scaleEffect(0.9)
                                .padding(.horizontal, 8)
                                .onAppear {
                                    if event.id == eventViewModel.events.last?.id {
                                        eventViewModel.fetchMoreEvents()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if eventViewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            }
            .background(Color("BackgroundColor"))
            .navigationTitle("Εκδηλώσεις")
            .onAppear {
                eventViewModel.fetchPOIs()
                eventViewModel.fetchFilteredEvents()
            }
            
        }
    }
}
