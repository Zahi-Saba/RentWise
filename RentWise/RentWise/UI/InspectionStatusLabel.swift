//
//  InspectionStatusLabel.swift
//  RentWise
//
//  Created by Bo Wen Chan on 30/10/2026.
//

import SwiftUI

struct InspectionStatusLabel: View {
    let status: ObservationStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {

            // The icon communicates status visually
            Image(systemName: status.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(status.color)
                .accessibilityHidden(true)

            // Primary text adapts automatically to Light Mode, Dark Mode and system contrast
            Text(status.displayName)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
