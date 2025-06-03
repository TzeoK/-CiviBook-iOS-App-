//
//  EditProfileView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 20/2/25.
//

import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.presentationMode) var presentationMode

    init(user: User) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user))
    }

    var body: some View {
        Form {
            /// Personal Info Section
            Section(header: Text("Στοιχεία Χρήστη")) {
                CustomTextField(title: "Όνομα", text: $viewModel.firstName, error: viewModel.fieldErrors["firstName"])
                CustomTextField(title: "Επώνυμο", text: $viewModel.lastName, error: viewModel.fieldErrors["lastName"])
                CustomTextField(title: "Username", text: $viewModel.username, error: viewModel.fieldErrors["username"])
                CustomTextField(title: "Τηλέφωνο", text: $viewModel.phoneNumber, error: viewModel.fieldErrors["phoneNumber"], keyboardType: .phonePad)

            }

            /// Profile Image Section
            ProfilePictureSection(selectedImage: $viewModel.selectedImage, showImagePicker: $viewModel.showImagePicker)

            /// Show General API Error Message
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding()
                }
            }

            /// **Save Button**
            Section {
                Button(action: {
                    viewModel.updateProfile()
                }) {
                    Text("Αποθήκευση Αλλαγών")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Επεξεργασία Προφίλ")
        .alert(isPresented: $viewModel.isUpdated) {
            Alert(
                title: Text("Success"),
                message: Text("Το προφίλ σας ενημερώθηκε."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
    }
}


struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var error: String?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField("Enter \(title.lowercased())", text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }
        }
    }
}

/// **Profile Picture Selection**
struct ProfilePictureSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool

    var body: some View {
        Section(header: Text("Εικόνα Προφίλ")) {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)

                    Button("Αλλαγή Εικόνας Προφίλ") {
                        showImagePicker = true
                    }
                    .foregroundColor(.blue)
                } else {
                    Button("Επιλογή Εικόνας Προφίλ") {
                        showImagePicker = true
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}
