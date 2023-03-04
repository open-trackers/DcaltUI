//
//  ServingWeight.swift
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

struct ServingWeight: View {
    @ObservedObject var serving: MServing

    @AppStorage("serving-weight-recents") private var recents = [Float]()
    private let maxRecents = 8

    var body: some View {
        Section("Weight") {
            WeightStepper(value: $serving.weight_g)

            if recents.first != nil {
                PresetValues(values: recents,
                             label: label,
                             onShortPress: {
                                 serving.weight_g = $0
                                 // recents.updateMRU(with: $0, maxCount: maxRecents)
                             })
            }
        }
    }

    private func label(_ value: Float) -> some View {
        Text("\(value, specifier: "%0.1f g")")
    }
}

struct ServingWeight_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                Form {
                    ServingWeight(serving: serving)
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
        serving.weight_g = 323
        return TestHolder(serving: serving)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
