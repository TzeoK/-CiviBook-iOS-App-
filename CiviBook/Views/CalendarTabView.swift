//
//  CalendarTabView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

//
//  CalendarTabView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

import SwiftUI
import FSCalendar

struct CalendarTabView: View {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshID = UUID()
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    


    var body: some View {
        NavigationView {
            VStack{
                ScrollView {
                    VStack {
                        if calendarViewModel.selectedPOI == nil {
                                Text("Επιλέξτε τοποθεσία") // Visible only when nil
                                    .foregroundColor(.red)
                                    .font(.headline)
                            }
                        // POI Selection Dropdown
                        Picker("Επιλέξτε τοποθεσία", selection: $calendarViewModel.selectedPOI) {
                            Text("Παρακαλώ επιλέξτε τοποθεσία").tag(nil as Int?)
                                .foregroundColor(calendarViewModel.selectedPOI == nil ? .red : .primary)
                            ForEach(calendarViewModel.calendarPois) { poi in
                                Text(poi.name).tag(poi.id as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 16)
                        .onChange(of: calendarViewModel.selectedPOI) { _, newPOI in
                                if newPOI != nil {
                                    Task{
                                        await calendarViewModel.fetchEvents() // Fetch events only if POI is selected
                                    }
                                    
                                }
                        }
                        
                        // Calendar Section
                        Text("Ημερολόγιο Εκδηλώσεων")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        if calendarViewModel.isLoading {
                            ProgressView("Φόρτωση εκδηλώσεων...")
                        } else if let error = calendarViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                        } else {
                            FSCalendarEventTabWrapper(
                                events: calendarViewModel.calendarEvents, // Use computed property
                                onDateSelected: { event in
                                    calendarViewModel.selectedEvent = event
                                }
                            )
                            .frame(height: 300)
                            .id(refreshID)
                        }
                        
                        if let selectedEvent = calendarViewModel.selectedEvent {
                            VStack {
                                EventCard(event: selectedEvent) { likedEvent in
                                    calendarViewModel.toggleLike(for: likedEvent)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .id(refreshID)
                            }
                        } else if calendarViewModel.selectedPOI != nil {
                            Text("Επιλέξτε ημέρα με εκδήλωση για λεπτομέρειες") 
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .top)
                    
                    .navigationTitle("Ημερολόγιο Εκδηλώσεων")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        Task {
                               if calendarViewModel.calendarPois.isEmpty {
                                   print("📅 Fetching POIs for Calendar...")
                                   await calendarViewModel.fetchPOIs()
                               }
                           }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }.background(Color("BackgroundColor"))
            .safeAreaInset(edge: .top) { Spacer().frame(height: 0) } 
        }
        .background(Color("BackgroundColor"))
        .ignoresSafeArea(.all)
        .refreshable {
            Task {
                print("🔄 Refreshing Calendar Tab")

                // ✅ Clear selection before fetching
                calendarViewModel.selectedEvent = nil
                calendarViewModel.selectedPOI = nil

                // ✅ Only reset if Calendar Tab is active
               
                    
                    calendarViewModel.calendarPois.removeAll()
                    calendarViewModel.calendarEvents.removeAll()
                    
                    await calendarViewModel.fetchPOIs()
                    await calendarViewModel.fetchEvents()
                

                // ✅ Force FSCalendar & EventCard re-render
                refreshID = UUID()
            }
        }
.background(Color("BackgroundColor"))
            .ignoresSafeArea(.all)
    }
}
