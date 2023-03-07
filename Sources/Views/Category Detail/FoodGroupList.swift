//
//  PresetList.swift
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

import DcaltLib
import TrackerUI

public struct FoodGroupList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    private var category: MCategory

    public init(category: MCategory) {
        self.category = category

        let sort = [NSSortDescriptor(keyPath: \MFoodGroup.userOrder, ascending: true)]
        let pred = NSPredicate(format: "category == %@", category)
        _categoryPresets = FetchRequest<MFoodGroup>(entity: MFoodGroup.entity(),
                                                    sortDescriptors: sort,
                                                    predicate: pred)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: FoodGroupList.self))

    @FetchRequest private var categoryPresets: FetchedResults<MFoodGroup>

    @State private var foodGroupSelection: FoodGroup?
    @State private var showPicker = false

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(categoryPresets, id: \.self) { preset in
                if let groupRaw = preset.groupRaw,
                   let foodGroup = FoodGroup(rawValue: groupRaw)
                {
                    Text("\(foodGroup.description)")
                    #if os(watchOS)
                        .listItemTint(foodGroupListItemTint)
                    #elseif os(iOS)
                        .listRowBackground(foodGroupListItemTint)
                    #endif
                }
            }
            .onMove(perform: moveAction)
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                addPresetButton {
                    Label("Add Food Group", systemImage: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                }
                .font(.title3)
                .tint(foodGroupColorDarkBg)
                .foregroundStyle(.tint)
            #endif
        }
        #if os(watchOS)
        .navigationTitle {
            NavTitle(title, color: foodGroupColorDarkBg)
        }
        #elseif os(iOS)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem {
                addPresetButton {
                    Text("Add Food Group")
                }
            }
        }
        #endif
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                FoodGroupPicker(foodGroups: unselectedCases, showPresets: $showPicker, onSelect: addPresetAction)
            }
            .interactiveDismissDisabled() // NOTE: needed to prevent home button from dismissing sheet
        }
    }

    private func addPresetButton(stuff: () -> some View) -> some View {
        Button(action: { showPicker = true }) {
            stuff()
        }
        .disabled(unselectedCases.count == 0)
    }

    // MARK: - Properties

    private var title: String {
        "Food Groups"
    }

    private var unselectedCases: [FoodGroup] {
        let selectedCases = categoryPresets.reduce(into: []) { $0.append($1.groupRaw) }
        return FoodGroup.allCases.filter { !selectedCases.contains($0.rawValue) }
    }

    private var maxOrder: Int16 {
        categoryPresets.last?.userOrder ?? 0
    }

    // MARK: - Actions

    private func addPresetAction(preset: FoodGroup) {
        do {
            _ = MFoodGroup.create(viewContext, category: category, userOrder: maxOrder + 1, groupRaw: preset.rawValue)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func deleteAction(offsets: IndexSet) {
        offsets.map { categoryPresets[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        MFoodGroup.move(categoryPresets, from: source, to: destination)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct FoodGroupList_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        @State var navData: Data?
        var body: some View {
            NavStack(navData: $navData) {
                FoodGroupList(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage"
        _ = MFoodGroup.create(ctx, category: category, userOrder: 0, groupRaw: FoodGroup.pork.rawValue)
        _ = MFoodGroup.create(ctx, category: category, userOrder: 1, groupRaw: FoodGroup.vegetables.rawValue)
        return TestHolder(category: category)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
