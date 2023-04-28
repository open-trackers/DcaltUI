//
//  ServDetCategory.swift
//
// Copyright 2023  OpenAlloc LLC
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

struct ServDetCategory: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject private var category: MCategory
    private var onSelect: (UUID?) -> Void

    init(category: MCategory,
         onSelect: @escaping (UUID?) -> Void)
    {
        self.category = category
        self.onSelect = onSelect
        let sort = MCategory.byName()
        _categories = FetchRequest<MCategory>(entity: MCategory.entity(),
                                              sortDescriptors: sort)
        _selected = State(initialValue: category.archiveID)
    }

    // MARK: - Locals

    @FetchRequest private var categories: FetchedResults<MCategory>

    @State private var selected: UUID?

//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
//                                category: String(describing: ExDetMCategory.self))

    // MARK: - Views

    var body: some View {
        platformView
            .onChange(of: selected) { nuArchiveID in
                onSelect(nuArchiveID)
            }
    }

    #if os(watchOS)
        private var platformView: some View {
            Picker("Category", selection: $selected) {
                ForEach(categories) { element in
                    Text(element.wrappedName)
                        .tag(element.archiveID)
                }
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Section("Category") {
                Picker("", selection: $selected) {
                    ForEach(categories) { element in
                        HStack {
                            Text(element.wrappedName)
                            Spacer()
                        }
                        .tag(element.archiveID)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    #endif
}

struct ServDetCategory_Previews: PreviewProvider {
    struct TestHolder: View {
        @ObservedObject var MCategory: MCategory
        var body: some View {
            ServDetCategory(category: MCategory, onSelect: { _ in })
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let MCategory1 = MCategory.create(ctx, userOrder: 0)
        MCategory1.name = "Beverage"
        let MCategory2 = MCategory.create(ctx, userOrder: 1)
        MCategory2.name = "Meat"
        try? ctx.save()
        return Form { TestHolder(MCategory: MCategory2) }
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
