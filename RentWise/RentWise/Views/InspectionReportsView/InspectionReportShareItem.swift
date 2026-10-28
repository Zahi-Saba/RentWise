//
//  InspectionReportShareItem.swift
//  RentWise
//
//  Created by Bo Wen Chan on 28/10/2026.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct InspectionReportShareItem: Transferable, Sendable {
    let fileURL: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { item in
            SentTransferredFile(item.fileURL, allowAccessingOriginalFile: false)
        }
    }
}
