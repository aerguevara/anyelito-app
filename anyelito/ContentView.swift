//
//  ContentView.swift
//  anyelito
//
//  Created by Anyelo Reyes on 3/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BabyTrackerViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                TabView {
                    DashboardView()
                        .environment(viewModel)
                        .tabItem {
                            Label("Dashboard", systemImage: "house.fill")
                        }
                    
                    GrowthView()
                        .environment(viewModel)
                        .tabItem {
                            Label("Crecimiento", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    
                    HealthView()
                        .environment(viewModel)
                        .tabItem {
                            Label("Salud", systemImage: "cross.fill")
                        }
                    
                    SettingsView()
                        .environment(viewModel)
                        .tabItem {
                            Label("Ajustes", systemImage: "gear")
                        }
                }
                .tint(.white) // Use tint for iOS 15+ 
                .preferredColorScheme(.dark)
            } else {
                ProgressView()
                    .preferredColorScheme(.dark)
                    .onAppear {
                        viewModel = BabyTrackerViewModel(modelContext: modelContext)
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
