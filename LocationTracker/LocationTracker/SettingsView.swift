//
//  SettingsView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 11/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Tracking")) {
                    Toggle("Enable Location Tracking", isOn: $locationManager.isTrackingEnabled)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
