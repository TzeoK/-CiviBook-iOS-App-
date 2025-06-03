import SwiftUI
import FSCalendar

struct FSCalendarWrapper: UIViewRepresentable {
    var events: [CalendarEvent] // Array of processed calendar events with individual dates
    @Environment(\.colorScheme) var colorScheme // Detect system-wide light/dark mode changes
    var onDateSelected: (String?) -> Void
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        configureAppearance(calendar: calendar)
        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        context.coordinator.events = events
        configureAppearance(calendar: uiView)
        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(events: events, onDateSelected: onDateSelected)
    }

    /// Configure the calendar appearance dynamically based on color scheme
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
        var events: [CalendarEvent]
        var onDateSelected: (String?) -> Void // Store the closure

        init(events: [CalendarEvent], onDateSelected: @escaping (String?) -> Void) {
            self.events = events
            self.onDateSelected = onDateSelected
        }

        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            // Check if there is an event for the given date
            let dayEvents = events.filter { event in
                Calendar.current.isDate(event.startDate, inSameDayAs: date)
            }
            return dayEvents.count
        }

        func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
            return nil
        }

        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            // Highlight event days with red
            let isEventDay = events.contains { event in
                Calendar.current.isDate(event.startDate, inSameDayAs: date)
            }
            return isEventDay ? .systemRed : nil
        }

        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor? {
            // Add a blue border for event days
            let isEventDay = events.contains { event in
                Calendar.current.isDate(event.startDate, inSameDayAs: date)
            }
            return isEventDay ? .systemBlue : nil
        }

        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderRadiusFor date: Date) -> CGFloat {
            // Customize the border for event days
            return 0.5 
        }

        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Handle date selection
            let selectedEvents = events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            print("Selected Date: \(date)")
            print("Events on Selected Date: \(selectedEvents.map(\.title))")
            let eventName = selectedEvents.first?.title
            onDateSelected(eventName) // Notify the parent view
        }
    }
}
