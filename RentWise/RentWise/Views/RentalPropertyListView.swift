//
//  RentalPropertyListView.swift
//  RentWise
//
//  Created by Zahi Saba on 30/9/2026.
//

import SwiftUI

struct RentalPropertyListView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    var body: some View {

        NavigationView {

            ZStack {

                                RentWiseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {

                        Text("RentWise")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Text("Find. Inspect. Decide.")
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal)

                    NavigationLink(
                        destination: AddRentalPropertyView(
                            viewModel: viewModel
                        )
                    ) {

                        PrimaryButton(
                            title: "Add Rental Property",
                            icon: "plus.circle.fill"
                        )
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {

                        NavigationLink(
                            destination:
                                SharedPropertyPreviewView()
                        ) {

                            DashboardButton(
                                title: "Shared",
                                icon: "square.and.arrow.down"
                            )
                        }

                        NavigationLink(
                            destination:
                                InspectionPlannerView(
                                    viewModel: viewModel
                                )
                        ) {

                            DashboardButton(
                                title: "Inspections",
                                icon: "calendar"
                            )
                        }
                    }
                    .padding(.horizontal)

                    SectionTitle(
                        title: "Your Shortlist"
                    )
                    .padding(.horizontal)

                    if viewModel.rentalProperties.isEmpty {

                        VStack(spacing: 12) {

                            Image(
                                systemName: "house"
                            )
                            .font(
                                .system(size: 40)
                            )
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )

                            Text(
                                "No rental properties saved yet."
                            )
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(30)
                        .background(
                                            RentWiseTheme.card
                        )
                        .cornerRadius(15)
                        .padding(.horizontal)

                        Spacer()

                    } else {

                        List {

                            ForEach(
                                viewModel.rentalProperties
                            ) { property in

                                NavigationLink(
                                    destination:
                                        RentalPropertyDetailView(
                                            viewModel: viewModel,
                                            property: property
                                        )
                                ) {

                                    RentalPropertyCard(
                                        property: property
                                    )
                                }
                                .listRowBackground(
                                                    RentWiseTheme.card
                                )
                            }
                            .onDelete { indexSet in

                                for index in indexSet {

                                    let property =
                                        viewModel
                                            .rentalProperties[index]

                                    viewModel
                                        .deleteRentalProperty(
                                            property
                                        )
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(
                            .hidden
                        )
                    }
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .onAppear {

                viewModel.loadRentalProperties()
            }
        }
        .preferredColorScheme(.dark)
    }
}
