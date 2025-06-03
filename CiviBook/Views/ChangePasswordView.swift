//
//  ChangePasswordView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 23/5/25.
//

import SwiftUI

struct ChangePasswordView: View {
    @StateObject var viewModel = ChangePasswordViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                passwordSection(
                    title: "Τρέχων Κωδικός",
                    binding: $viewModel.currentPassword,
                    error: viewModel.fieldErrors["currentPassword"]
                )

                passwordSection(
                    title: "Νέος Κωδικός",
                    binding: $viewModel.newPassword,
                    error: viewModel.fieldErrors["newPassword"]
                )

                passwordSection(
                    title: "Επιβεβαίωση Κωδικού",
                    binding: $viewModel.confirmPassword,
                    error: viewModel.fieldErrors["confirmPassword"]
                )

                if let generalError = viewModel.errorMessage {
                    Section {
                        Text(generalError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Αλλαγή Κωδικού") {
                        viewModel.changePassword()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitle("Αλλαγή Κωδικού", displayMode: .inline)
            .alert(isPresented: $viewModel.isPasswordChanged) {
                Alert(
                    title: Text("Επιτυχία"),
                    message: Text("Ο κωδικός άλλαξε με επιτυχία."),
                    dismissButton: .default(Text("Εντάξει")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Helper for reusability and compiler efficiency
    private func passwordSection(title: String, binding: Binding<String>, error: String?) -> some View {
        Section(header: Text(title)) {
            SecureField(title, text: binding)
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}
