//
//  PrimaryButton.swift
//  RentWise
//
//  Created by Zahi Saba on 5/10/2026.
//

import Foundation
import SwiftUI

struct PrimaryButton: View {

    let title: String
    let icon: String

    var body: some View {

        HStack {

            Image(systemName: icon)
                .font(.title2)

            Text(title)
                .font(.headline)

            Spacer()
        }
        .foregroundColor(
                            RentWiseTheme.mainText
        )
        .padding()
        .background(
                            RentWiseTheme.accent
        )
        .cornerRadius(15)
    }
}
