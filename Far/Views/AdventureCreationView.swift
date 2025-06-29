//
//  AdventureCreationView.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


//
//  AdventureCreationView.swift
//  Far
//
//  Modal view for creating new adventures
//

import SwiftUI

struct AdventureCreationView: View {
    let onSave: (String, Data?) -> ()
    let onDismiss: () -> Void
    
    @State private var adventureName = ""
    @State private var showingImagePicker = false
    @State private var selectedImageData: Data?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HeaderSection()
                
                AdventureNameSection(adventureName: $adventureName)
                
                PhotoSection(
                    selectedImageData: $selectedImageData,
                    showingCamera: $showingCamera,
                    showingPhotoLibrary: $showingPhotoLibrary
                )
                
                Spacer()
                
                ActionButtons(
                    adventureName: adventureName,
                    selectedImageData: selectedImageData,
                    onSave: onSave,
                    onDismiss: onDismiss
                )
            }
            .padding()
            .navigationTitle("New Adventure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, imageData: $selectedImageData)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary, imageData: $selectedImageData)
            }
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("New Adventure Discovered!")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("You've been at this location for 5+ minutes. Capture this moment!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Adventure Name Section
struct AdventureNameSection: View {
    @Binding var adventureName: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Adventure Name")
                    .font(.headline)
                
                Spacer()
                
                if !adventureName.isEmpty {
                    Text("\(adventureName.count)/50")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            TextField("Name this place...", text: $adventureName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .onAppear {
                    // Auto-focus the text field when the view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
                .onChange(of: adventureName) { newValue in
                    // Limit to 50 characters
                    if newValue.count > 50 {
                        adventureName = String(newValue.prefix(50))
                    }
                }
            
            // Suggested names
            if adventureName.isEmpty {
                SuggestedNamesView(onNameSelected: { name in
                    adventureName = name
                })
            }
        }
    }
}

// MARK: - Suggested Names View
struct SuggestedNamesView: View {
    let onNameSelected: (String) -> Void
    
    private let suggestions = [
        "Coffee Shop", "Park", "Restaurant", "Home", "Work",
        "Gym", "Library", "Store", "Beach", "Trail"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onNameSelected(suggestion)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Photo Section
struct PhotoSection: View {
    @Binding var selectedImageData: Data?
    @Binding var showingCamera: Bool
    @Binding var showingPhotoLibrary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Photo")
                .font(.headline)
            
            if let imageData = selectedImageData,
               let uiImage = UIImage(data: imageData) {
                SelectedPhotoView(
                    image: uiImage,
                    onRemove: { selectedImageData = nil }
                )
            } else {
                PhotoOptionsView(
                    showingCamera: $showingCamera,
                    showingPhotoLibrary: $showingPhotoLibrary
                )
            }
        }
    }
}

// MARK: - Selected Photo View
struct SelectedPhotoView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Photo selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

// MARK: - Photo Options View
struct PhotoOptionsView: View {
    @Binding var showingCamera: Bool
    @Binding var showingPhotoLibrary: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                PhotoOptionButton(
                    icon: "camera.fill",
                    title: "Camera",
                    action: { showingCamera = true }
                )
                
                PhotoOptionButton(
                    icon: "photo.on.rectangle",
                    title: "Photo Library",
                    action: { showingPhotoLibrary = true }
                )
            }
            
            Text("Optional - Add a photo to remember this adventure")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Photo Option Button
struct PhotoOptionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Action Buttons
struct ActionButtons: View {
    let adventureName: String
    let selectedImageData: Data?
    let onSave: (String, Data?) -> ()
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Save Adventure") {
                let name = adventureName.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(name.isEmpty ? "Unnamed Adventure" : name, selectedImageData)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            
            Button("Skip This Time") {
                onDismiss()
                dismiss()
            }
            .buttonStyle(.bordered)
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

#Preview {
    AdventureCreationView(
        onSave: { name, data in
            print("Saving adventure: \(name)")
        },
        onDismiss: {
            print("Dismissing adventure creation")
        }
    )
}
