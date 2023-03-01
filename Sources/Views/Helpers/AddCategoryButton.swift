//
//  AddCategoryButton.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import DcaltLib
import TrackerUI

public struct AddCategoryButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    public init() {}

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        AddElementButton(elementName: "Category",
                         onCreate: createAction,
                         onAfterSave: afterSaveAction)
    }

    // MARK: - Properties

    private var maxOrder: Int16 {
        do {
            return try MCategory.maxUserOrder(viewContext) ?? 0
        } catch {
            // logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    private func createAction() -> MCategory {
        let nu = MCategory.create(viewContext, userOrder: maxOrder)
        nu.name = "New Category"
        nu.userOrder = maxOrder + 1
        return nu
    }

    private func afterSaveAction(_ nu: MCategory) {
        router.path.append(DcaltRoute.categoryDetail(nu.uriRepresentation))
    }
}

// struct AddCategoryButton_Previews: PreviewProvider {
//    static var previews: some View {
//        AddCategoryButton()
//    }
// }
