//
//  InspectionCard.swift
//  RentWise
//
//  Created by Zahi Saba on 5/10/2026.
//

import SwiftUI

struct InspectionCard: View {

    let inspection: RentalInspection
    let address: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Image(
                    systemName: "mappin.circle.fill"
                )
                .foregroundColor(
                                    RentWiseTheme.accent
                )

                Text(address)
                    .font(.headline)
                    .foregroundColor(
                                        RentWiseTheme.mainText
                    )

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .foregroundColor(
                                    RentWiseTheme.secondaryText
                )
            }

            HStack {

                Image(
                    systemName: "calendar"
                )
                .foregroundColor(
                                    RentWiseTheme.secondaryText
                )

                Text(
                    inspection.startTime,
                    style: .date
                )
                .foregroundColor(
                                    RentWiseTheme.secondaryText
                )
            }

            HStack {

                Image(
                    systemName: "clock"
                )
                .foregroundColor(
                                    RentWiseTheme.secondaryText
                )

                Text(
                    inspection.startTime,
                    style: .time
                )

                Text("-")

                Text(
                    inspection.endTime,
                    style: .time
                )
            }
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
    }
}
