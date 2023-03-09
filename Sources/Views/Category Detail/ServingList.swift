//
//  ServingList.swift
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

public struct ServingList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    private var category: MCategory

    public init(category: MCategory) {
        self.category = category

        let sort = MServing.byUserOrder()
        let pred = MServing.getPredicate(category: category)
        _servings = FetchRequest<MServing>(entity: MServing.entity(),
                                           sortDescriptors: sort,
                                           predicate: pred)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingList.self))

    @FetchRequest private var servings: FetchedResults<MServing>

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(servings, id: \.self) { serving in
                Button(action: { detailAction(serving: serving) }) {
                    Text("\(serving.name ?? "unknown")")
                        .foregroundColor(servingColor)
                }
                #if os(watchOS)
                .listItemTint(servingListItemTint)
                #elseif os(iOS)
                .listRowBackground(servingListItemTint)
                #endif
            }
            .onMove(perform: moveAction)
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                AddServingButton(category: category)
                    .font(.title3)
                    .tint(servingColorDarkBg)
                    .foregroundStyle(.tint)
            #endif
        }
        #if os(iOS)
        .navigationTitle("Servings")
        .toolbar {
            ToolbarItem {
                AddServingButton(category: category)
            }
        }
        #endif
    }

    // MARK: - Properties

    private var servingColor: Color {
        colorScheme == .light ? servingColorLiteBg : servingColorDarkBg
    }

    // MARK: - Actions

    private func detailAction(serving: MServing) {
        logger.notice("\(#function)")
        Haptics.play()

        router.path.append(DcaltRoute.servingDetail(serving.uriRepresentation))
    }

    private func deleteAction(offsets: IndexSet) {
        logger.notice("\(#function)")
        Haptics.play()

        offsets.map { servings[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        logger.notice("\(#function)")
        Haptics.play()

        MServing.move(servings, from: source, to: destination)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct ServingList_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        @State var navData: Data?
        var body: some View {
            DcaltNavStack(navData: $navData) {
                ServingList(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Whiskey"
        return TestHolder(category: category)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
