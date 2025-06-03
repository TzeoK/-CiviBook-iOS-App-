//
//  CiviBookApp.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 3/5/24.
//

import SwiftUI

@main
struct CiviBookApp: App {
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var hasCheckedLoginState = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCheckedLoginState {
                    if loginViewModel.isLoggedOut {
                        LoginView()
                            .environmentObject(loginViewModel)
                            .environmentObject(homeViewModel)
                    } else {
                        HomeView()
                            .environmentObject(loginViewModel)
                            .environmentObject(homeViewModel)
                    }
                } else {
                    // Temporary blank screen
                    Color("BackgroundColor").edgesIgnoringSafeArea(.all)
                        .onAppear {
                            // Simulate checking stored login state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hasCheckedLoginState = true
                            }
                        }
                }
            }
        }
    }
}

