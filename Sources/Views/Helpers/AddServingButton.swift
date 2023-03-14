//
//  AddServingButton.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import DcaltLib
import TrackerUI

public struct AddServingButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    private var category: MCategory

    public init(category: MCategory) {
        self.category = category
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        AddElementButton(elementName: "Serving",
                         onCreate: createAction,
                         onAfterSave: afterSaveAction)
    }

    // MARK: - Properties

    private var maxOrder: Int16 {
        do {
            return try MServing.maxUserOrder(viewContext, category: category) ?? 0
        } catch {
            // logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    private func createAction() -> MServing {
        MServing.create(viewContext,
                        category: category,
                        userOrder: maxOrder + 1,
                        name: "New Serving")
    }

    private func afterSaveAction(_ nu: MServing) {
        router.path.append(DcaltRoute.servingDetail(nu.uriRepresentation))
    }
}

struct AddServingButton_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Back & Bicep"
        return AddServingButton(category: category)
    }
}
