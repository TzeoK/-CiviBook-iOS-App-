//
//  CalendarEvent.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//

import Foundation

struct CalendarTabEvent: Codable, Identifiable {
    let id: Int
    let eventName: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case id
        case eventName = "event_name"
        case date
    }
}
