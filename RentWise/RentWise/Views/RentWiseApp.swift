//
//  RentWiseApp.swift
//  RentWise
//
//  Created by Zahi Saba on 20/10/2026.
//
import SwiftUI
import CoreData

@main
struct RentWiseApp: App {
    
    @StateObject private var viewModel: RentWiseViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        
        let repository = CoreDataRentalPropertyRepository(
            context: context
        )
        
        _viewModel = StateObject(
            wrappedValue: RentWiseViewModel(
                repository: repository
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            RentalPropertyListView(
                viewModel: viewModel
            )
        }
    }
}
