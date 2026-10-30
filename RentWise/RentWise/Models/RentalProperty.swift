//
//  RentalProerty.swift
//  RentWise
//
//  Created by Zahi Saba on 20/10/2026.
//
import Foundation

struct RentalProperty: Identifiable {

    let id: UUID
    var address: String
    var weeklyRent: Double
    var sourceURL: String?
    var rooms: [InspectionRoom] = []

    init(
        id: UUID = UUID(),
        address: String,
        weeklyRent: Double,
        sourceURL: String? = nil
    ) {
        self.id = id
        self.address = address
        self.weeklyRent = weeklyRent
        self.sourceURL = sourceURL
    }

    var rentLabel: String {
        weeklyRent > 0
            ? String(format: "$%.0f / week", weeklyRent)
            : "Rent not supplied"
    }
}
