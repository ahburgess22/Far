//
//  ImagePicker.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


//
//  ImagePicker.swift
//  Far
//
//  UIKit wrapper for camera and photo library access
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary
        
        var uiImagePickerSourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera:
                return .camera
            case .photoLibrary:
                return .photoLibrary
            }
        }
    }
    
    let sourceType: SourceType
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    init(sourceType: SourceType, imageData: Binding<Data?>) {
        self.sourceType = sourceType
        self._imageData = imageData
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType.uiImagePickerSourceType
        picker.allowsEditing = true
        
        // Camera-specific settings
        if sourceType == .camera {
            picker.cameraDevice = .rear
            picker.cameraCaptureMode = .photo
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selectedImage: UIImage?
            
            // Try to get edited image first, then original
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }
            
            // Convert to JPEG data with compression
            if let image = selectedImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Image Picker Availability Helper
extension ImagePicker {
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    static func availableMediaTypes(for sourceType: SourceType) -> [String]? {
        return UIImagePickerController.availableMediaTypes(for: sourceType.uiImagePickerSourceType)
    }
}

// MARK: - Image Processing Extensions
extension UIImage {
    /// Resize image to a maximum dimension while maintaining aspect ratio
    func resized(to maxDimension: CGFloat) -> UIImage? {
        let size = self.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        // Don't upscale
        guard ratio < 1 else { return self }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Compress image data to a target size in bytes
    func compressedJPEGData(targetBytes: Int) -> Data? {
        var compression: CGFloat = 1.0
        let step: CGFloat = 0.1
        
        while compression > 0 {
            if let data = self.jpegData(compressionQuality: compression),
               data.count <= targetBytes {
                return data
            }
            compression -= step
        }
        
        // Return highly compressed version if target cannot be met
        return self.jpegData(compressionQuality: 0.1)
    }
}

// MARK: - Camera Permission Helper
class CameraPermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            DispatchQueue.main.async {
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }
    
    var shouldShowPermissionAlert: Bool {
        return authorizationStatus == .denied
    }
}

// MARK: - Required Imports
import AVFoundation