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

    var body: some View {
        Section("Weight") {
            WeightStepper(value: $serving.weight_g)
            HStack {
                Text("Clear")
                    .onTapGesture {
                        serving.weight_g = 0
                    }
                #if os(iOS)
                    Spacer()
                    Text("+50 g")
                        .onTapGesture {
                            serving.weight_g += 50
                        }
                #endif
                Spacer()
                Text("+100 g")
                    .onTapGesture {
                        serving.weight_g += 100
                    }
            }
            .foregroundStyle(.tint)
        }
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
            .accentColor(.orange)
            .symbolRenderingMode(.hierarchical)
    }
}
