//
//  ServDetVolume.swift
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

struct ServDetVolume: View {
    @ObservedObject var serving: MServing
    var forceFocus: Bool = false

    var body: some View {
        Section("Volume") {
            VolumeStepper(value: $serving.volume_mL, forceFocus: forceFocus)

            HStack {
                Text("Clear")
                    .onTapGesture {
                        serving.volume_mL = 0
                    }
                #if os(iOS)
                    Spacer()
                    Text("+50 ml")
                        .onTapGesture {
                            serving.volume_mL += 50
                        }
                #endif
                Spacer()
                Text("+100 ml")
                    .onTapGesture {
                        serving.volume_mL += 100
                    }
            }
            .foregroundStyle(.tint)
        }
    }
}

struct ServDetVolume_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                Form {
                    ServDetVolume(serving: serving)
                }
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 1)
        category.name = "Beverage"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Stout"
        serving.volume_mL = 323
        return TestHolder(serving: serving)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
