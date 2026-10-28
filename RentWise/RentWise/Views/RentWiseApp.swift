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
    @StateObject private var reportsViewModel: InspectionReportsViewModel
    
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
        
        _reportsViewModel = StateObject(
            wrappedValue: InspectionReportsViewModel(
                repository: repository
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            RentWiseRootView(
                viewModel: viewModel,
                reportsViewModel: reportsViewModel
            )
        }
    }
}
