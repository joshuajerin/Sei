//
//  SeiApp.swift
//  Sei
//
//  Created by Joshua Jerin on 5/12/25.
//

import SwiftUI

@main
struct SeiApp: App {
    @StateObject private var session = SessionManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    ContentView()
                        .environmentObject(session)
                        .onAppear {
                            print("Showing ContentView - User is logged in")
                        }
                } else {
                    AuthView()
                        .environmentObject(session)
                        .onAppear {
                            print("Showing AuthView - User is not logged in")
                        }
                }
            }
        }
    }
}
