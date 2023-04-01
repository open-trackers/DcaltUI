//
//  AddServingButton.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import TextFieldPreset

import DcaltLib
import TrackerUI

public struct AddServingButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    private var category: MCategory

    public init(category: MCategory) {
        self.category = category
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: AddServingButton.self))

    #if os(iOS)
        @State private var showBulkAdd = false
        @State private var selected = Set<ServingPreset>()
    #endif

    // MARK: - Views

    public var body: some View {
        AddElementButton(elementName: "Serving",
                         onLongPress: longPressAction,
                         onCreate: createAction,
                         onAfterSave: afterSaveAction)
        #if os(iOS)
            .sheet(isPresented: $showBulkAdd) {
                NavigationStack {
                    BulkPresetsPicker(selected: $selected,
                                      presets: filteredPresets,
                                      label: { Text($0.description) })
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", action: cancelBulkAddAction)
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add Servings", action: bulkAddAction)
                                    .disabled(selected.count == 0)
                            }
                        }
                }
            }
        #endif
    }

    // MARK: - Properties

    private var filteredPresets: ServingPresetDict {
        category.filteredPresets ?? servingPresets
    }

    private var maxOrder: Int16 {
        do {
            return try MServing.maxUserOrder(viewContext, category: category) ?? 0
        } catch {
            // logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    #if os(iOS)
        private func cancelBulkAddAction() {
            showBulkAdd = false
        }
    #endif

    #if os(iOS)
        private func bulkAddAction() {
            do {
                // produce an ordered array of presets from the unordered set
                let presets = filteredPresets.flatMap(\.value).filter { selected.contains($0) }
                selected.removeAll()

                try MServing.bulkCreate(viewContext, category: category, presets: presets)
                try viewContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
            showBulkAdd = false
        }
    #endif

    private func longPressAction() {
        #if os(watchOS)
            Haptics.play(.warning)
        #elseif os(iOS)
            showBulkAdd = true
        #endif
    }

    private func createAction() -> MServing {
        MServing.create(viewContext,
                        category: category,
                        userOrder: maxOrder + 1)
    }

    private func afterSaveAction(_ nu: MServing) {
        router.path.append(DcaltRoute.servingDetail(nu.uriRepresentation))
    }
}

struct AddServingButton_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Back & Bicep"
        return AddServingButton(category: category)
    }
}
