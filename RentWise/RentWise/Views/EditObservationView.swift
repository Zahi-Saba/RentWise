//
//  EditObservationView.swift
// RentWise
//
//  Created by Zahi Saba on 6/10/2026.
//

import Foundation
import SwiftUI

struct EditObservationView: View {

    @ObservedObject var viewModel:
    RentWiseViewModel

    let observation:
        InspectionObservation

    @State private var status:
        ObservationStatus

    @State private var notes: String

    @Environment(\.presentationMode)
    private var presentationMode

    init(
        viewModel: RentWiseViewModel,
        observation: InspectionObservation
    ) {

        self.viewModel = viewModel
        self.observation = observation

        _status = State(
            initialValue: observation.status
        )

        _notes = State(
            initialValue: observation.notes
        )
    }

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
                        title: "Edit Observation"
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Inspection Item")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Text(
                            criterionName(
                                observation.criterion
                            )
                        )
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

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Text("Status")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        Picker(
                            "Status",
                            selection: $status
                        ) {

                            ForEach(
                                ObservationStatus.allCases,
                                id: \.self
                            ) { status in

                                Text(
                                    statusName(status)
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

                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(
                                                RentWiseTheme.mainText
                            )

                        TextField(
                            "Update your observation",
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

                        viewModel.updateObservation(
                            observation: observation,
                            status: status,
                            notes: notes
                        )

                        if viewModel.errorMessage.isEmpty {

                            presentationMode
                                .wrappedValue
                                .dismiss()
                        }

                    } label: {

                        PrimaryButton(
                            title: "Save Changes",
                            icon: "checkmark.circle.fill"
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Edit Observation")
        .navigationBarTitleDisplayMode(.inline)
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
