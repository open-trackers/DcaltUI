//
//  ServDetName.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TextFieldPreset

import DcaltLib
import TrackerUI

public struct ServDetName: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var serving: MServing
    let tint: Color

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServDetName.self))

    // MARK: - Views

    public var body: some View {
        Section {
            TextFieldPreset($serving.wrappedName,
                            prompt: "Enter serving name",
                            axis: .vertical,
                            presets: filteredPresets,
                            pickerLabel: { Text($0.description) },
                            onSelect: selectAction)
            #if os(watchOS)
                .padding(.bottom)
            #endif
                .tint(tint)

            // KLUDGE: unable to get textfield to display multiple lines, so conditionally
            //         including full text as a courtesy.
            #if os(watchOS)
                if serving.wrappedName.count > 20 {
                    Text(serving.wrappedName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            #endif
        } header: {
            Text("Name")
        }
        #if os(iOS)
        .font(.title3)
        #endif
    }

    // MARK: - Properties

    private var filteredPresets: ServingPresetDict {
        serving.category?.filteredPresets ?? servingPresets
    }

    // MARK: - Actions

    private func selectAction(_ preset: ServingPreset) {
        do {
            serving.populate(from: preset)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct ServDetName_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            Form {
                ServDetName(serving: serving, tint: .green)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Stout and Beer and Hops and other stuff"
        serving.calories = 323
        return TestHolder(serving: serving)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
