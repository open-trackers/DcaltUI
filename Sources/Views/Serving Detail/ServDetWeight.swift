//
//  ServDetWeight.swift
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

struct ServDetWeight: View {
    @ObservedObject var serving: MServing

    @AppStorage("serving-weight-recents") private var recents: [Float] = [10, 50, 100, 200]

    #if os(watchOS)
        private let minPresetButtonWidth: CGFloat = 70
        private let maxRecents = 4
    #elseif os(iOS)
        private let minPresetButtonWidth: CGFloat = 80
        private let maxRecents = 8
    #endif

    var body: some View {
        Section("Weight") {
            WeightStepper(value: $serving.weight_g)

            if recents.first != nil {
                PresetValues(values: recents,
                             minButtonWidth: minPresetButtonWidth,
                             label: label,
                             onShortPress: {
                                 serving.weight_g = $0
                             })
            }
        }
        .onDisappear {
            recents.updateMRU(with: serving.weight_g, maxCount: maxRecents)
        }
    }

    private func label(_ value: Float) -> some View {
        Text("\(value, specifier: "%0.1f g")")
    }
}

struct ServDetWeight_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                Form {
                    ServDetWeight(serving: serving)
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
