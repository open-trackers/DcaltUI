//
//  ServDetCalories.swift
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

struct ServDetCalories: View {
    @ObservedObject var serving: MServing

    @AppStorage("serving-calorie-recents") private var recents: [Int16] = [100, 200, 400, 800]

    #if os(watchOS)
        private let minPresetButtonWidth: CGFloat = 70
        private let maxRecents = 4
    #elseif os(iOS)
        private let minPresetButtonWidth: CGFloat = 80
        private let maxRecents = 8
    #endif

    var body: some View {
        Section {
            CalorieStepper(value: $serving.calories)

            if recents.first != nil {
                PresetValues(values: recents,
                             minButtonWidth: minPresetButtonWidth,
                             label: label,
                             onShortPress: {
                                 serving.calories = $0
                             })
                             .padding(.vertical, 3)
            }

            Button(action: { serving.calories = 0 }) {
                Text("Set to zero (0 cal)")
                // .foregroundStyle(servingColorDarkBg)
            }
        } header: {
            Text("Calories")
        }
        .onDisappear {
            guard serving.calories != 0 else { return }
            recents.updateMRU(with: serving.calories, maxCount: maxRecents)
        }
    }

    private func label(_ value: Int16) -> some View {
        Text("\(value)")
    }
}

struct ServDetCalories_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                Form {
                    ServDetCalories(serving: serving)
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
            .accentColor(.green)
    }
}
