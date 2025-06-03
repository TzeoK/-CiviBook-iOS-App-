//
//  BookingsTabView.swift
//  CiviBook
//
//  Created by Georgios Kyriakopoulos on 8/2/25.
//

import SwiftUI

struct BookingsTabView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Τοποθεσίες")
                .font(.title)
            
            if homeViewModel.isLoading {
                ProgressView("Εύρεση τοποθεσιών...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                List(homeViewModel.pois) { poi in
                    NavigationLink(destination: PoiDetailsView(poi: poi)) {
                        HStack {
                            if let poiImg = poi.poi_img, !poiImg.isEmpty, let imageURL = URL(string: "http://192.168.1.240:8000/storage/\(poiImg)") {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        .shadow(radius: 5)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 50, height: 50)
                                }
                            } else {
                                Image(systemName: "mappin.and.ellipse")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    .shadow(radius: 5)
                            }

                            VStack(alignment: .leading) {
                                Text(poi.name)
                                    .font(.headline)
                                Text(poi.display_address ?? "δεν βρέθηκε διεύθυνση")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 10)
                        }
                        .padding()
                    }
                }
                .scrollContentBackground(.hidden) // Hide default list background
                .background(Color("BackgroundColor")) // apply custom background to entire List
                .refreshable {
                    homeViewModel.fetchPOIs()
                }
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // ensures full coverage
        .background(Color("BackgroundColor"))
    }
}

#Preview {
    BookingsTabView().environmentObject(HomeViewModel())
}
