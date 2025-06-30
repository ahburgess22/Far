//
//  ContentView.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


//
//  ContentView.swift
//  Far
//
//  Main content view for the Far app
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = FarViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HeaderView()
                    
                    LocationStatusCard(viewModel: viewModel)
                    
                    if viewModel.isTimingLocation {
                        AdventureTimerCard(adventureService: viewModel.adventureService)  // ✅ Pass service directly
                    }
                    
                    AdventureStatsCard(viewModel: viewModel)
                    
                    if !viewModel.recentAdventures.isEmpty {
                        RecentAdventuresCard(
                            adventures: viewModel.recentAdventures,
                            onAdventureDelete: viewModel.deleteAdventure
                        )
                    } else {
                        EmptyStateView()
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Far")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("View All Adventures") {
                            viewModel.showingAdventuresList = true
                        }
                        
                        Button("Refresh Location") {
                            viewModel.refreshLocation()
                        }
                        
                        Button("Settings") {
                            viewModel.showingSettings = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAdventureCreation) {
                AdventureCreationView(
                    onSave: viewModel.createAdventure,
                    onDismiss: viewModel.dismissAdventureCreation
                )
            }
            .sheet(isPresented: $viewModel.showingAdventuresList) {
                AdventuresListView(adventures: viewModel.adventureService.sortedAdventures, viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                viewModel.startLocationTracking()
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🗺️")
                .font(.system(size: 64))
            
            Text("Discover Your World")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
}

// MARK: - Location Status Card
struct LocationStatusCard: View {
    @ObservedObject var viewModel: FarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatusIndicator(isActive: viewModel.isLocationActive)
                
                VStack(alignment: .leading) {
                    Text("Location Status")
                        .font(.headline)
                    
                    Text(viewModel.locationStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let coordinate = viewModel.currentCoordinate {
                VStack(spacing: 4) {
                    Text("Current Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Lat: \(coordinate.latitude, specifier: "%.4f")")
                        Spacer()
                        Text("Lng: \(coordinate.longitude, specifier: "%.4f")")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Adventure Timer Card
struct AdventureTimerCard: View {
    @ObservedObject var adventureService: AdventureService  // ✅ Observe service directly
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("New Location Detected")
                        .font(.headline)
                    
                    Text("Stay for \(adventureService.formattedTimeRemaining) more")  // ✅ Direct access
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Text(adventureService.formattedTimerDuration)  // ✅ Direct access
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                ProgressView(value: adventureService.timerProgress)  // ✅ Direct access
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Adventure Stats Card
struct AdventureStatsCard: View {
    @ObservedObject var viewModel: FarViewModel
    
    var body: some View {
        HStack(spacing: 32) {
            StatView(
                title: "Adventures",
                value: "\(viewModel.totalAdventures)",
                color: .blue
            )
            
            StatView(
                title: "This Month",
                value: "\(viewModel.currentMonthAdventures)",
                color: .green
            )
            
            StatView(
                title: "Months Active",
                value: "\(viewModel.uniqueMonths)",
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Recent Adventures Card
struct RecentAdventuresCard: View {
    let adventures: [Adventure]
    let onAdventureDelete: (Adventure) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Adventures")
                    .font(.headline)
                
                Spacer()
                
                Text("\(adventures.count) of \(adventures.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(adventures) { adventure in
                    AdventureRowView(
                        adventure: adventure,
                        onDelete: { onAdventureDelete(adventure) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.red)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct AdventureRowView: View {
    let adventure: Adventure
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(adventure.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(adventure.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if adventure.hasPhotos {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Menu {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Adventures Yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start exploring! When you visit a new place and stay for 5+ minutes, Far will help you capture that moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
