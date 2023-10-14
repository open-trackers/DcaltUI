//
//  CatDetName.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TextFieldPreset

import DcaltLib
import TrackerUI

public struct CatDetName: View {
    // MARK: - Parameters

    @ObservedObject private var category: MCategory

    public init(category: MCategory) {
        self.category = category
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            TextFieldPreset($category.wrappedName,
                            prompt: "Enter category name",
                            axis: .vertical,
                            presets: categoryNamePresets)
            {
                Text($0.description)
                    .foregroundStyle(.tint)
            }
            #if os(watchOS)
            .padding(.bottom)
            #endif
            #if os(iOS)
            .font(.title3)
            #endif
            .textInputAutocapitalization(.words)

            // KLUDGE: unable to get textfield to display multiple lines, so conditionally
            //         including full text as a courtesy.
            #if os(watchOS)
                if category.wrappedName.count > 20 {
                    Text(category.wrappedName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            #endif
        } header: {
            Text("Name")
        }
    }

    // MARK: - Properties
}

struct CatDetName_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        var body: some View {
            Form {
                CatDetName(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage and this and that and other things"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Stout"
        serving.calories = 323
        return TestHolder(category: category)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
