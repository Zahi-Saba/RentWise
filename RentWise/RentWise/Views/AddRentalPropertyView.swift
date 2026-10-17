//
//  AddRentalPropertyView.swift
//  RentWise
//
//  Created by Zahi Saba on 2/10/2026.
//

import SwiftUI

struct AddRentalPropertyView: View {

    @ObservedObject var viewModel: RentWiseViewModel

    @State private var address: String = ""
    @State private var weeklyRent: String = ""
    @State private var inputError: String = ""
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
                    title: "New Rental Property"
                )

                Text(
                    "Add a property to your rental shortlist."
                )
                .foregroundColor(
                                    RentWiseTheme.secondaryText
                )

                DarkTextField(
                    title: "Property Address",
                    placeholder: "Enter property address",
                    text: $address
                )

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text("Weekly Rent")
                        .font(.headline)
                        .foregroundColor(
                                            RentWiseTheme.mainText
                        )

                    TextField(
                        "Enter weekly rent",
                        text: $weeklyRent
                    )
                    .keyboardType(.decimalPad)
                    .padding()
                    .foregroundColor(
                                        RentWiseTheme.mainText
                    )
                    .background(
                                        RentWiseTheme.card
                    )
                    .cornerRadius(12)
                }

                if !inputError.isEmpty {

                    Text(inputError)
                        .foregroundColor(.red)
                }

                if !viewModel.errorMessage.isEmpty {

                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }

                Button {

                    inputError = ""

                    if let rent = Double(
                        weeklyRent
                    ) {

                        viewModel.addRentalProperty(
                            address: address,
                            weeklyRent: rent
                        )

                        if viewModel
                            .errorMessage
                            .isEmpty {

                            address = ""
                            weeklyRent = ""

                            showConfirmation = true
                        }

                    } else {

                        inputError =
                            "Please enter a valid weekly rent."
                    }

                } label: {

                    PrimaryButton(
                        title: "Add Rental Property",
                        icon: "plus.circle.fill"
                    )
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Add Property")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .preferredColorScheme(.dark)
        .alert(
            "Rental Property Added",
            isPresented: $showConfirmation
        ) {
            Button("OK") {
            }
        } message: {

            Text(
                "The rental property was saved successfully."
            )
        }
    }
}
