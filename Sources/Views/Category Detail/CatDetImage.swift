//
//  CatDetImage.swift
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

struct CatDetImage: View {
    // MARK: - Parameters

    @ObservedObject var category: MCategory
    var forceFocus: Bool

    // MARK: - Views

    var body: some View {
        Section {
            ImageStepper(initialName: category.imageName,
                         imageNames: systemImageNames,
                         forceFocus: forceFocus)
            {
                category.imageName = $0
            }
            #if os(watchOS)
            .imageScale(.small)
            #elseif os(iOS)
            .imageScale(.large)
            #endif
        } header: {
            Text("Image")
        }
    }

    // MARK: - Properties
}

struct CatDetImage_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        var body: some View {
            Form {
                CatDetImage(category: category, forceFocus: false)
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
