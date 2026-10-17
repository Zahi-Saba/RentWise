//
//  InspectionChecklistView.swift
//  RentWise
//
//  Created by Zahi Saba on 2/10/2026.
//

import Foundation
import SwiftUI

struct InspectionChecklistView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    let inspection: RentalInspection

    @State private var criterion: InspectionCriterion = .noise
    @State private var status: ObservationStatus = .notChecked
    @State private var notes: String = ""

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
                        title: "Inspection Checklist"
                    )

                    HStack {

                        Image(
                            systemName: "house.fill"
                        )
                        .foregroundColor(
                                            RentWiseTheme.accent
                        )

                        Text(
                            viewModel.propertyAddress(
                                for: inspection.rentalPropertyID
                            )
                        )
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

                        Text("Inspection Item")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Picker(
                            "Inspection Item",
                            selection: $criterion
                        ) {

                            ForEach(
                                InspectionCriterion.allCases,
                                id: \.self
                            ) { criterion in

                                Text(
                                    criterionName(
                                        criterion
                                    )
                                )
                                .tag(criterion)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(
                                            RentWiseTheme.accent
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

                        Text("Result")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Picker(
                            "Result",
                            selection: $status
                        ) {

                            ForEach(
                                ObservationStatus.allCases,
                                id: \.self
                            ) { status in

                                Text(
                                    statusName(
                                        status
                                    )
                                )
                                .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(
                                            RentWiseTheme.accent
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

                        Text("Observation Notes")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        TextField(
                            "What did you notice?",
                            text: $notes
                        )
                        .padding()
                        .foregroundColor(
                                            RentWiseTheme.mainText
                        )
                        .background(
                                            RentWiseTheme.secondaryCard
                        )
                        .cornerRadius(12)
                    }
                    .padding()
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

                        viewModel.recordObservation(
                            inspectionID: inspection.id,
                            criterion: criterion,
                            status: status,
                            notes: notes
                        )

                        if viewModel.errorMessage.isEmpty {

                            notes = ""
                        }

                    } label: {

                        PrimaryButton(
                            title: "Save Observation",
                            icon: "checkmark.circle.fill"
                        )
                    }

                    Divider()

                    SectionTitle(
                        title: "Saved Observations"
                    )

                    if viewModel.observations.isEmpty {

                        Text(
                            "No observations saved yet."
                        )
                        .foregroundColor(
                                            RentWiseTheme.secondaryText
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(25)
                        .background(
                                            RentWiseTheme.card
                        )
                        .cornerRadius(15)

                    } else {

                        ForEach(
                            viewModel.observations
                        ) { observation in

                            NavigationLink(
                                destination:
                                    EditObservationView(
                                        viewModel: viewModel,
                                        observation: observation
                                    )
                            ) {

                                HStack {

                                    ObservationCard(
                                        observation: observation
                                    )

                                    Image(
                                        systemName: "pencil"
                                    )
                                    .foregroundColor(
                                                        RentWiseTheme.accent
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {

            viewModel.loadRentalProperties()

            viewModel.loadObservations(
                for: inspection.id
            )
        }
        .preferredColorScheme(.dark)
    }

    private func criterionName(
        _ criterion: InspectionCriterion
    ) -> String {

        switch criterion {

        case .noise:
            return "Noise"

        case .daylight:
            return "Daylight"

        case .storage:
            return "Storage"

        case .roomSpace:
            return "Room Space"

        case .transport:
            return "Transport"
        }
    }

    private func statusName(
        _ status: ObservationStatus
    ) -> String {

        switch status {

        case .notChecked:
            return "Not Checked"

        case .meetsNeeds:
            return "Meets Needs"

        case .doesNotMeetNeeds:
            return "Does Not Meet Needs"

        case .needsClarification:
            return "Needs Clarification"
        }
    }
}
