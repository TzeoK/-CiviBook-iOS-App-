//
//  ForgetPasswordView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 19/3/25.
//

import SwiftUI

struct ForgetPasswordView: View {
    
    @EnvironmentObject var viewModel: ForgetPasswordViewModel
    @State private var navigateToLogin: Bool = false // State for navigation

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

                        // Main form background
                        VStack {
                            // Header
                            Text("Ξεχάσατε τον κωδικό?")
                                .font(.largeTitle)
                                .bold()

                            Text("Εισάγετε email για να λάβετε mail επαναφοράς")
                                .font(.caption2)
                                .opacity(0.8)
                                .padding(.bottom)

                            // Email Input Field
                            TextField("Email", text: $viewModel.email)
                                .padding()
                                .frame(width: 300, height: 50)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(20)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)

                            // Submit Button
                            Button(action: {
                                viewModel.sendResetLink()
                            }) {
                                Text("Αποστολή mail επαναφοράς")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .frame(width: 300)
                            .contentShape(Rectangle())
                            .buttonStyle(PressableButtonStyle())

                            // Error or success message
                            if !viewModel.message.isEmpty {
                                Text(viewModel.message)
                                    .foregroundColor(viewModel.isError ? .red : .green)
                                    .padding()
                                    .multilineTextAlignment(.center)
                                    .frame(width: 300)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)

                        Spacer()

                        // Links
                        VStack {
                            Text("Θυμάστε τον κωδικό?")
                                .font(.footnote)

                            Button("Πίσω στην Σύνδεση") {
                                navigateToLogin = true
                            }
                            .font(.footnote)
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
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView()
        }
    }
}


struct ForgetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgetPasswordView()
            .environmentObject(ForgetPasswordViewModel()) // Inject ViewModel
    }
}
