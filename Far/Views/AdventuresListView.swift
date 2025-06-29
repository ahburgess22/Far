//
//  SupportingViews.swift
//  Far
//
//  Additional views for adventures list, settings, and other UI components
//

import SwiftUI
import CoreLocation

// MARK: - Adventures List View
struct AdventuresListView: View {
    let adventures: [Adventure]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if adventures.isEmpty {
                    EmptyAdventuresView()
                } else {
                    AdventuresGrid(adventures: adventures)
                }
            }
            .navigationTitle("All Adventures")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Empty Adventures View
struct EmptyAdventuresView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Adventures Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start exploring new places and Far will automatically capture your adventures when you stay somewhere for 5+ minutes.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Adventures Grid
struct AdventuresGrid: View {
    let adventures: [Adventure]
    @State private var selectedAdventure: Adventure?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(adventures) { adventure in
                    AdventureGridCard(adventure: adventure)
                        .onTapGesture {
                            selectedAdventure = adventure
                        }
                }
            }
            .padding()
        }
        .sheet(item: $selectedAdventure) { adventure in
            AdventureDetailView(adventure: adventure)
        }
    }
}

// MARK: - Adventure Grid Card
struct AdventureGridCard: View {
    let adventure: Adventure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo or placeholder
            Group {
                if let photoData = adventure.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                }
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(adventure.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(adventure.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Adventure Detail View
struct AdventureDetailView: View {
    let adventure: Adventure
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero image or placeholder
                    Group {
                        if let photoData = adventure.photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .frame(height: 250)
                                
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(adventure.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        AdventureInfoSection(adventure: adventure)
                        
                        AdventureLocationSection(adventure: adventure)
                    }
                    .padding()
                }
            }
            .navigationTitle("Adventure")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Adventure Info Section
struct AdventureInfoSection: View {
    let adventure: Adventure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Date & Time", systemImage: "calendar")
                .font(.headline)
            
            Text(adventure.timestamp, style: .date)
                .font(.body)
            
            Text(adventure.timestamp, style: .time)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Adventure Location Section
struct AdventureLocationSection: View {
    let adventure: Adventure
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Latitude: \(adventure.coordinate.latitude, specifier: "%.6f")")
                    .font(.body)
                
                Text("Longitude: \(adventure.coordinate.longitude, specifier: "%.6f")")
                    .font(.body)
            }
            .foregroundColor(.secondary)
            
            if let address = adventure.address {
                Text(address)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: FarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            List {
                LocationSettingsSection(viewModel: viewModel)
                
                DataSection(
                    viewModel: viewModel,
                    showingResetAlert: $showingResetAlert,
                    showingExportSheet: $showingExportSheet
                )
                
                AppInfoSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("This will delete all your adventures. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Location Settings Section
struct LocationSettingsSection: View {
    @ObservedObject var viewModel: FarViewModel
    
    var body: some View {
        Section("Location") {
            HStack {
                Label("Status", systemImage: "location")
                Spacer()
                Text(viewModel.locationStatus)
                    .foregroundColor(.secondary)
            }
            
            if let coordinate = viewModel.currentCoordinate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Position")
                        .font(.subheadline)
                    
                    Text("Lat: \(coordinate.latitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Lng: \(coordinate.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Refresh Location") {
                viewModel.refreshLocation()
            }
        }
    }
}

// MARK: - Data Section
struct DataSection: View {
    @ObservedObject var viewModel: FarViewModel
    @Binding var showingResetAlert: Bool
    @Binding var showingExportSheet: Bool
    
    var body: some View {
        Section("Data") {
            HStack {
                Label("Adventures", systemImage: "map")
                Spacer()
                Text("\(viewModel.totalAdventures)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Active Months", systemImage: "calendar")
                Spacer()
                Text("\(viewModel.uniqueMonths)")
                    .foregroundColor(.secondary)
            }
            
            Button("Export Data") {
                showingExportSheet = true
            }
            
            Button("Reset All Data") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - App Info Section
struct AppInfoSection: View {
    var body: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com")!) {
                Label("Source Code", systemImage: "link")
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @ObservedObject var viewModel: FarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Export Your Adventures")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Share your adventure data as a JSON file that can be imported into another device.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Export Data") {
                    exportData()
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        guard let data = viewModel.exportAdventures() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [data],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
}