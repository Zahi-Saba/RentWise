//
//  SectionTitle.swift
// RentWise
//
//  Created by Zahi Saba on 5/10/2026.
//

import SwiftUI

struct SectionTitle: View {

    let title: String

    var body: some View {

        Text(title)
            .font(.title2)
            .bold()
            .foregroundColor(
                                RentWiseTheme.mainText
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }
}
