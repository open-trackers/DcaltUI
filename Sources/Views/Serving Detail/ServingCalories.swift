//
//  ServingCalories.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import DcaltLib
import TrackerUI

struct ServingCalories: View {
    @ObservedObject var serving: MServing

    @AppStorage("serving-calories-recents") private var recents = [Int16]()
    private let maxRecents = 8

    var body: some View {
        Section("Calories") {
            CalorieStepper(value: $serving.calories)

            if recents.first != nil {
                PresetValues(values: recents,
                             label: label,
                             onShortPress: {
                                 serving.calories = $0
                                 // recents.updateMRU(with: $0, maxCount: maxRecents)
                             })
            }
        }
    }

    private func label(_ value: Int16) -> some View {
        Text("\(value)")
    }
}

struct ServingCalories_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                Form {
                    ServingCalories(serving: serving)
                }
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
