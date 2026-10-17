//
//  DashboardButton.swift
// RentWise
//
//  Created by Zahi Saba on 5/10/2026.
//

import SwiftUI

struct DashboardButton: View {

    let title: String
    let icon: String

    var body: some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title2)

            Text(title)
                .font(.subheadline)
                .bold()
        }
        .foregroundColor(
                            RentWiseTheme.mainText
        )
        .frame(
            maxWidth: .infinity
        )
        .padding()
        .background(
                            RentWiseTheme.card
        )
        .cornerRadius(15)
    }
}
