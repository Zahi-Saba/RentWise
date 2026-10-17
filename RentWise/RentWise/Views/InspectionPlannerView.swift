//
//  InspectionPlannerView.swift
//  RentWise
//
//  Created by Zahi Saba on 2/10/2026.
//

import Foundation
import SwiftUI

struct InspectionPlannerView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    var body: some View {

        ZStack {

                            RentWiseTheme.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    SectionTitle(
                        title: "Upcoming Inspections"
                    )

                    if viewModel.inspections.isEmpty {

                        VStack(spacing: 12) {

                            Image(
                                systemName: "calendar.badge.clock"
                            )
                            .font(.system(size: 40))
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )

                            Text(
                                "No upcoming inspections scheduled."
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

                    } else {

                        ForEach(
                            viewModel.inspections
                        ) { inspection in

                            NavigationLink(
                                destination:
                                    InspectionChecklistView(
                                        viewModel: viewModel,
                                        inspection: inspection
                                    )
                            ) {

                                InspectionCard(
                                    inspection: inspection,
                                    address:
                                        viewModel.propertyAddress(
                                            for:
                                                inspection
                                                    .rentalPropertyID
                                        )
                                )
                            }
                        }
                    }

                    NavigationLink(
                        destination:
                            InspectionHistoryView(
                                viewModel: viewModel
                            )
                    ) {

                        PrimaryButton(
                            title: "View Inspection History",
                            icon: "clock.arrow.circlepath"
                        )
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Inspection Planner")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {

            viewModel.loadRentalProperties()
            viewModel.loadUpcomingInspections()
        }
        .preferredColorScheme(.dark)
    }
}
