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
    var forceFocus: Bool = false

    var body: some View {
        Section("Calories") {
            CalorieStepper(value: $serving.calories, forceFocus: forceFocus)

            HStack {
                Text("Clear")
                    .onTapGesture {
                        serving.calories = 0
                    }
                #if os(iOS)
                    Spacer()
                    Text("+50 cal")
                        .onTapGesture {
                            serving.calories += 50
                        }
                #endif
                Spacer()
                Text("+100 cal")
                    .onTapGesture {
                        serving.calories += 100
                    }
            }
            .foregroundStyle(.tint)
        }
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
