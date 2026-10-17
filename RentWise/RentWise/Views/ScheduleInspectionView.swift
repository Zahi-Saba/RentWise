//
//  ScheduleInspectionView.swift
//  RentWise
//
//  Created by Zahi Saba on 2/10/2026.
//

import SwiftUI

struct ScheduleInspectionView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    let property: RentalProperty

    @State private var startTime = Date()
    @State private var endTime = Date()

    @State private var showConfirmation = false

    var body: some View {

        ZStack {

                            RentWiseTheme.background
                .ignoresSafeArea()

            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                SectionTitle(
                    title: "Schedule Inspection"
                )

                HStack(spacing: 12) {

                    Image(
                        systemName: "house.fill"
                    )
                    .foregroundColor(
                                        RentWiseTheme.accent
                    )

                    Text(property.address)
                        .font(.headline)
                        .foregroundColor(
                                            RentWiseTheme.mainText
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

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("Start Time")
                        .font(.headline)
                        .foregroundColor(
                                            RentWiseTheme.mainText
                        )

                    DatePicker(
                        "Start",
                        selection: $startTime
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
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

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("End Time")
                        .font(.headline)
                        .foregroundColor(
                                            RentWiseTheme.mainText
                        )

                    DatePicker(
                        "End",
                        selection: $endTime
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
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

                if !viewModel.errorMessage.isEmpty {

                    Text(
                        viewModel.errorMessage
                    )
                    .foregroundColor(.red)
                }

                Button {

                    viewModel.scheduleInspection(
                        rentalPropertyID: property.id,
                        startTime: startTime,
                        endTime: endTime
                    )

                    if viewModel
                        .errorMessage
                        .isEmpty {

                        showConfirmation = true
                    }

                } label: {

                    PrimaryButton(
                        title: "Schedule Inspection",
                        icon: "calendar.badge.plus"
                    )
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("New Inspection")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .preferredColorScheme(.dark)
        .alert(
            "Inspection Scheduled",
            isPresented: $showConfirmation
        ) {

            Button("OK") {
            }

        } message: {

            Text(
                "The inspection was scheduled successfully."
            )
        }
    }
}
