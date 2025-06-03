//
//  NotificationModel.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 12/2/25.
//

import Foundation

struct NotificationResponse: Codable {
    let notifications: [NotificationItem]
}

struct NotificationItem: Identifiable, Codable {
    let id: String
    let created_at: String
    var read_at: String? 
    let data: NotificationData

    struct NotificationData: Codable {
        let event_name: String
        let reservation_status: String
        let message: String
    }

    var isRead: Bool {
        return read_at != nil
    }
}
