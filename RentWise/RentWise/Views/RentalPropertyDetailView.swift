//
//  RentalPropertyDetailView.swift
//  RentWise
//
//  Created by Zahi Saba on 2/10/2026.
//

import SwiftUI

struct RentalPropertyDetailView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    let property: RentalProperty

    var body: some View {

        ZStack {

                            RentWiseTheme.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        HStack {

                            Image(
                                systemName: "house.fill"
                            )
                            .font(.title2)
                            .foregroundColor(
                                                RentWiseTheme.accent
                            )

                            Text("Property")
                                .font(.headline)
                                .foregroundColor(
                                                    RentWiseTheme.secondaryText
                                )
                        }

                        Text(property.address)
                            .font(.title2)
                            .bold()
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Text(
                            property.rentLabel
                        )
                        .font(.headline)
                        .foregroundColor(
                                            RentWiseTheme.secondaryText
                        )
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                                        RentWiseTheme.card
                    )
                    .cornerRadius(15)

                    NavigationLink(
                        destination: ScheduleInspectionView(
                            viewModel: viewModel,
                            property: property
                        )
                    ) {

                        PrimaryButton(
                            title: "Schedule Inspection",
                            icon: "calendar.badge.plus"
                        )
                    }

                    SectionTitle(
                        title: "Latest Inspection Notes"
                    )

                    if let inspection =
                        viewModel.latestPropertyInspection {

                        HStack {

                            Image(
                                systemName: "clock"
                            )
                            .foregroundColor(
                                                RentWiseTheme.accent
                            )

                            Text(
                                inspection.startTime,
                                style: .date
                            )

                            Text("-")

                            Text(
                                inspection.startTime,
                                style: .time
                            )
                        }
                        .foregroundColor(
                                            RentWiseTheme.secondaryText
                        )

                        ForEach(
                            viewModel.latestPropertyObservations
                        ) { observation in

                            ObservationCard(
                                observation: observation
                            )
                        }

                    } else {

                        VStack(spacing: 10) {

                            Image(
                                systemName:
                                    "checklist"
                            )
                            .font(.title)
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )

                            Text(
                                "No inspection notes saved yet."
                            )
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(25)
                        .background(
                                            RentWiseTheme.card
                        )
                        .cornerRadius(15)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Property Details")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {

            viewModel.loadLatestInspectionNotes(
                for: property.id
            )
        }
        .preferredColorScheme(.dark)
    }
}
