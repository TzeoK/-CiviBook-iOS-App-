//
//  FSCalendarEventTabWrapper.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 13/2/25.
//


import SwiftUI
import FSCalendar

struct FSCalendarEventTabWrapper: UIViewRepresentable {
    var events: [HomeTabEvent]
    var onDateSelected: (HomeTabEvent?) -> Void
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        configureAppearance(calendar: calendar)
        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        let oldEvents = context.coordinator.events
            context.coordinator.events = events

            // Only reload if events actually changed
            if oldEvents.map(\.id) != events.map(\.id) {
                uiView.reloadData()
            }
            
            configureAppearance(calendar: uiView)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(events: events, onDateSelected: onDateSelected)
    }

    private func configureAppearance(calendar: FSCalendar) {
        if colorScheme == .dark {
            calendar.appearance.titleDefaultColor = .white
            calendar.appearance.selectionColor = .systemBlue
            calendar.appearance.todayColor = .systemGreen
            calendar.appearance.eventDefaultColor = .systemRed
            calendar.appearance.headerTitleColor = .white
            calendar.appearance.weekdayTextColor = .white
        } else {
            calendar.appearance.titleDefaultColor = .black
            calendar.appearance.selectionColor = .systemBlue
            calendar.appearance.todayColor = .systemGreen
            calendar.appearance.eventDefaultColor = .systemRed
            calendar.appearance.headerTitleColor = .black
            calendar.appearance.weekdayTextColor = .black
        }
    }

    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var events: [HomeTabEvent]
        var onDateSelected: (HomeTabEvent?) -> Void

        init(events: [HomeTabEvent], onDateSelected: @escaping (HomeTabEvent?) -> Void) {
            self.events = events
            self.onDateSelected = onDateSelected
        }

        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return events.filter { event in
                guard let eventStart = event.eventStartDate.toDate(),
                      let eventEnd = event.eventEndDate.toDate() else { return false }
                return Calendar.current.isDate(eventStart, inSameDayAs: date) ||
                       Calendar.current.isDate(eventEnd, inSameDayAs: date)
            }.count
        }


        func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
            return nil
        }

        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            let isEventDay = events.contains { event in
                guard let eventStart = event.eventStartDate.toDate(),
                      let eventEnd = event.eventEndDate.toDate() else { return false }
                return (eventStart...eventEnd).contains(date)
            }
            return isEventDay ? UIColor.systemRed.withAlphaComponent(0.7) : nil
        }


        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor? {
            let hasEvent = events.contains { event in
                guard let eventStart = event.eventStartDate.toDate(),
                      let eventEnd = event.eventEndDate.toDate() else { return false }
                return (eventStart...eventEnd).contains(date)
            }
            return hasEvent ? .systemBlue : nil
        }


        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
            let matchingEvents = events.filter { event in
                guard let eventStart = event.eventStartDate.toDate(),
                      let eventEnd = event.eventEndDate.toDate() else { return false }
                return Calendar.current.isDate(eventStart, inSameDayAs: date) ||
                       Calendar.current.isDate(eventEnd, inSameDayAs: date)
            }
            
            return matchingEvents.isEmpty ? nil : [.systemRed]
        }

        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let selectedEvents = events.filter { event in
                guard let eventStart = event.eventStartDate.toDate(),
                      let eventEnd = event.eventEndDate.toDate() else { return false }
                return (eventStart...eventEnd).contains(date)
            }
            print("Selected Date: \(date)")
            print("Events on Selected Date: \(selectedEvents.map(\.name))")
            onDateSelected(selectedEvents.first)
        }
    }


}

extension String {
    func toDate() -> Date? { // Returns optional Date instead of defaulting to Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self) // Returns nil if conversion fails
    }
}

