//
//  ServingName.swift
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

public struct ServingName: View {
    // MARK: - Parameters

    @ObservedObject private var serving: MServing

    public init(serving: MServing) {
        self.serving = serving

        _servingPreset = State(initialValue: ServingPreset(title: serving.wrappedName, calories: Float(serving.calories)))
    }

    // MARK: - Locals

    @State private var servingPreset: ServingPreset

    // MARK: - Views

    public var body: some View {
        Section {
            TextFieldWithPresets($servingPreset, // serving.wrappedName
                                 prompt: "Enter serving name",
                                 presets: filteredServingPresets)
            { _, preset in
                serving.name = preset.title
                serving.volume_mL = Float(preset.volume_mL ?? 0)
                serving.weight_g = Float(preset.weight_g ?? 0)
                serving.calories = Int16(preset.calories)

            } label: {
                Text($0.title)
            }
        } header: {
            Text("Name")
        }
    }

    // MARK: - Properties

    private var filteredServingPresets: ServingPresetDict {
        guard let foodGroupElems = serving.category?.foodGroups?.allObjects as? [MFoodGroup],
              foodGroupElems.first != nil
        else { return servingPresets }

        let foodGroups = foodGroupElems.map { FoodGroup(rawValue: $0.groupRaw) }

        return servingPresets.filter { foodGroups.contains($0.key) }
    }
}

struct ServingName_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            Form {
                ServingName(serving: serving)
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
        return TestHolder(serving: serving)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
