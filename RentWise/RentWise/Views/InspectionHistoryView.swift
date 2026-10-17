//
//  InspectionHistoryView.swift
//  RentWise
//
//  Created by Zahi Saba on 4/10/2026.
//

import SwiftUI

struct InspectionHistoryView: View {

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
                        title: "Past Inspections"
                    )

                    if viewModel.inspectionHistory.isEmpty {

                        VStack(spacing: 12) {

                            Image(
                                systemName: "clock"
                            )
                            .font(.system(size: 40))
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )

                            Text(
                                "No past inspections."
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
                            viewModel.inspectionHistory
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

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Inspection History")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .onAppear {

            viewModel.loadRentalProperties()
            viewModel.loadInspectionHistory()
        }
        .preferredColorScheme(.dark)
    }
}
