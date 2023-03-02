//
//  CategoryName.swift
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

public struct CategoryName: View {
    // MARK: - Parameters

    @ObservedObject private var category: MCategory

    public init(category: MCategory) {
        self.category = category
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            TextFieldWithPresets($category.wrappedName,
                                 prompt: "Enter category name",
                                 presets: categoryNamePresets) { _, _ in
                // nothing to set other than the name
            } label: {
                Text($0)
                    .foregroundStyle(.tint)
            }
        } header: {
            Text("Name")
        }
    }

    // MARK: - Properties
}

struct CategoryName_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        var body: some View {
            Form {
                CategoryName(category: category)
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
