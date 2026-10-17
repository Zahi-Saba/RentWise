//
//  ObservationCard.swift
//  RentWise
//
//  Created by Zahi Saba on 5/10/2026.
//

import SwiftUI

struct ObservationCard: View {

    let observation: InspectionObservation

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Image(
                    systemName: "checkmark.circle.fill"
                )
                .foregroundColor(
                                    RentWiseTheme.accent
                )

                Text(
                    criterionName(
                        observation.criterion
                    )
                )
                .font(.headline)
                .foregroundColor(
                                    RentWiseTheme.mainText
                )

                Spacer()
            }

            Text(
                statusName(
                    observation.status
                )
            )
            .foregroundColor(
                                RentWiseTheme.secondaryText
            )

            Text(observation.notes)
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
