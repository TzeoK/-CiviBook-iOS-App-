import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var viewModel: LoginViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var navigateToRegister: Bool = false
    @State private var navigateToForgetPassword: Bool = false


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BackgroundColor").edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack {
                        // Title Text
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

                        // Main login form background
                        VStack {
                            // Welcome Text
                            Text("Καλώς Ορίσατε")
                                .font(.largeTitle)
                                .bold()

                            Text("Εισάγετε username και κωδικό")
                                .font(.caption2)
                                .opacity(0.8)
                                .padding(.bottom)

                            // Email TextField
                            TextField("Email/username", text: $viewModel.identifier)
                                .padding()
                                .frame(width: 300, height: 50)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(20)
                                .autocapitalization(.none)

                            // Password SecureField
                            SecureField("Password", text: $viewModel.password)
                                .padding()
                                .frame(width: 300, height: 50)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(20)
                                .autocapitalization(.none)

                            // Login Button
                            Button(action: {
                                viewModel.login()
                            }) {
                                Text("Login")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .frame(width: 300)
                            .contentShape(Rectangle())
                            .buttonStyle(PressableButtonStyle())
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }

                        Spacer()

                        // Links and Buttons outside of login form
                        VStack {
                            Text("Δέν μπορείτε να συνδεθείτε?")
                                .font(.footnote)

                            Button("Ξέχασα τον κωδικό μου") {
                                // Handle forgot password action
                                navigateToForgetPassword = true
                            }
                            .font(.footnote)
                            .padding(.bottom, 5)

                            Text("Νέος χρήστης του Civibook?")
                                .font(.footnote)

                            Button("Εγγραφή") {
                                                           navigateToRegister = true
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
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            HomeView()
                .environmentObject(viewModel)
                .environmentObject(homeViewModel)
        }
        .fullScreenCover(isPresented: $navigateToRegister) {
                    RegisterView()
        }
        .fullScreenCover(isPresented: $navigateToForgetPassword) {
            ForgetPasswordView().environmentObject(ForgetPasswordViewModel())
        }

    }
}


struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(HomeViewModel())
            .environmentObject(LoginViewModel()) 
    }
}
