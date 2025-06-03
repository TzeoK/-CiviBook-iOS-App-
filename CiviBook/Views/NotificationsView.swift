//
//  NotificationsView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 12/2/25.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    // Buttons for actions
                    HStack {
                        Button(action: markAllAsRead) {
                            Text("Ανάγνωση Όλων")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: deleteAllNotifications) {
                            Text("Διαγραφή Όλων")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    if homeViewModel.notifications.isEmpty {
                        Text("Δεν υπάρχουν ειδοποιήσεις.")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(homeViewModel.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .listRowBackground(Color("BackgroundColor"))
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        
                    }
                    
                    
                }
                .navigationTitle("Ειδοποιήσεις")
                .onAppear {
                    print("🔄 Opening Notifications Tab... Fetching Notifications")
                    homeViewModel.fetchNotifications()
                    
                    // Debugging to confirm data is fetched
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        print("📩 Notifications Count: \(homeViewModel.notifications.count)")
                        for notification in homeViewModel.notifications {
                            print("📬 Event: \(notification.data.event_name), Read: \(notification.isRead)")
                        }
                    }
                }
                
            }
        }
    }
    
    // API call to mark all notifications as read
    func markAllAsRead() {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else { return }
        
        guard let url = URL(string: "http://192.168.1.240:8000/api/notifications/mark-all-read") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                let currentDate = ISO8601DateFormatter().string(from: Date())
                
                for i in homeViewModel.notifications.indices {
                    homeViewModel.notifications[i].read_at = currentDate
                }
                
                homeViewModel.unreadCount = 0
            }
        }.resume()
    }
    
    
    // API call to delete all notifications
    func deleteAllNotifications() {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else { return }
        
        guard let url = URL(string: "http://192.168.1.240:8000/api/notifications/delete-all") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                homeViewModel.notifications.removeAll()
                homeViewModel.unreadCount = 0
            }
        }.resume()
    }
    
}

struct NotificationRow: View {
    let notification: NotificationItem
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Notification Box
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.data.message)
                    .font(.body)
                    .foregroundColor(notification.isRead ? .gray : (colorScheme == .dark ? .white : .black))

                Text(notification.created_at.toGreekDateFormat())
                    .font(.caption)
                    .foregroundColor(notification.isRead ? .gray : (colorScheme == .dark ? .gray : Color(UIColor.darkGray))) // Darker gray in Light Mode
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(notification.isRead
                ? (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white) // Read notification background
                : (colorScheme == .dark ? Color.blue.opacity(0.5) : Color.blue.opacity(0.2)) // Unread notification background
            )
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal, 16)
            .onTapGesture {
                if notification.read_at == nil {
                    homeViewModel.markNotificationAsRead(notificationId: notification.id)
                }
            }

            
            if notification.read_at == nil {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .offset(x: -5, y: -5)
            }
        }
    }
}



extension String {
    func toGreekDateFormat() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: self) else { return "Άγνωστη ημερομηνία" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "el_GR") // Greek locale
        formatter.dateFormat = "EEEE dd/MM/yyyy - HH:mm" // for example: Σάββατο 29/01/2025 - 15:30
        
        return formatter.string(from: date).capitalized
    }
}
