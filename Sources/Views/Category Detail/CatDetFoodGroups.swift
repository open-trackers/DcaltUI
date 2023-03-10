//
//  ServingFoodGroups.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import DcaltLib
import TrackerUI

public struct CatDetFoodGroups: View {
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    @ObservedObject private var category: MCategory

    public init(category: MCategory) {
        self.category = category
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            Button(action: foodGroupListAction) {
                HStack {
                    Text("Food Groups")
                    Spacer()
                    Text(foodGroupCount > 0 ? String(format: "%d", foodGroupCount) : "none")
                    #if os(watchOS)
                        .foregroundStyle(foodGroupColorDarkBg)
                    #endif
                }
            }
        } footer: {
            Text("The food group presets available for this category. (If ‘none’, all will be available.)")
        }
    }

    // MARK: - Properties

    private var foodGroupCount: Int {
        category.foodGroups?.count ?? 0
    }

    // MARK: - Actions

    private func foodGroupListAction() {
        router.path.append(DcaltRoute.foodGroupList(category.uriRepresentation))
    }
}

struct CatDetFoodGroups_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        var body: some View {
            Form {
                CatDetFoodGroups(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Stout"
        serving.calories = 323
        return TestHolder(category: category)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
