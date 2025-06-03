//
//  RegisterView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 20/2/25.
//

import SwiftUI

struct RegisterView: View {
    
    @StateObject private var viewModel = RegisterViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BackgroundColor").edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack {
                        // Title
                        Text("CiviBook")
                            .font(.system(size: 60))
                            .bold()

                        // Image
                        Image("LoginImage")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 170)
                            .cornerRadius(20)
                            .padding()

                        Spacer()

                        // Register Form
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Δημιουργήστε Λογαριασμό")
                                .font(.largeTitle)
                                .bold()

                            Text("Συμπληρώστε την φόρμα")
                                .font(.caption2)
                                .opacity(0.8)
                                .padding(.bottom)

                            // Username
                            TextField("Username", text: $viewModel.username)
                                .textFieldStyle(OutlinedTextFieldStyle())
                            if let error = viewModel.fieldErrors["username"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // First Name
                            TextField("Όνομα", text: $viewModel.firstName)
                                .textFieldStyle(OutlinedTextFieldStyle())
                            if let error = viewModel.fieldErrors["firstName"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // Last Name
                            TextField("Επώνυμο", text: $viewModel.lastName)
                                .textFieldStyle(OutlinedTextFieldStyle())
                            if let error = viewModel.fieldErrors["lastName"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // Email
                            TextField("Email", text: $viewModel.email)
                                .textFieldStyle(OutlinedTextFieldStyle())
                                .keyboardType(.emailAddress)
                            if let error = viewModel.fieldErrors["email"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // Password
                            SecureField("Κωδικός", text: $viewModel.password)
                                .textFieldStyle(OutlinedTextFieldStyle())
                            if let error = viewModel.fieldErrors["password"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // Confirm Password
                            SecureField("Επιβεβαίωση Κωδικού", text: $viewModel.passwordConfirmation)
                                .textFieldStyle(OutlinedTextFieldStyle())
                            if let error = viewModel.fieldErrors["passwordConfirmation"] {
                                Text(error).foregroundColor(.red).font(.caption)
                            }

                            // General error message
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding(.top)
                            }

                            // Register Button
                            Button(action: {
                                viewModel.register()
                            }) {
                                Text("Εγγραφή")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .frame(width: 300)
                            .contentShape(Rectangle())
                            .buttonStyle(PressableButtonStyle())
                            .padding(.top)

                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)

                        Spacer()

                        // Navigation to Login
                        VStack {
                            Text("Έχετε ήδη λογαριασμό?")
                                .font(.footnote)

                            Button("Συνδεθείτε εδώ") {
                                viewModel.navigateToLogin = true
                            }
                            .font(.footnote)
                            .padding(.bottom, 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isRegistered) {
            LoginView()
        }
        .fullScreenCover(isPresented: $viewModel.navigateToLogin) {
            LoginView()
        }
    }
}





// Custom TextField Style
struct OutlinedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(width: 300, height: 50)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(20)
    }
}
