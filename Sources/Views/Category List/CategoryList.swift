//
//  CategoryList.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import DcaltLib
import TrackerLib
import TrackerUI

extension MCategory: @retroactive Named {}

// This is the shared 'ContentView' for both iOS and watchOS platforms
public struct CategoryList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    // MARK: - Parameters

    public init() {}

    // MARK: - Locals

    private let logCategoryPublisher = NotificationCenter.default.publisher(for: .logCategory)
    private let logServingPublisher = NotificationCenter.default.publisher(for: .logServing)

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: CategoryList.self))

    // MARK: - Views

    public var body: some View {
        CellList(cell: categoryCell,
                 addButton: { AddCategoryButton() })
        {
            #if os(watchOS)
                Group {
                    todayButton
                    AddCategoryButton()
                    settingsButton
                    aboutButton
                }
                .accentColor(.blue) // NOTE: make the images really blue
                .symbolRenderingMode(.hierarchical)
            #elseif os(iOS)
                EmptyView()
            #endif
        }
        #if os(watchOS)
        // .navigationBarTitleDisplayMode(.large)
        .navigationTitle {
            calorieTitle
                .font(.title3)
        }
        #elseif os(iOS)
        // .navigationBarTitleDisplayMode(.inline) // reduces the space allocated
        .toolbar {
            ToolbarItem(placement: .principal) {
                calorieTitle
                    .font(.title2)
            }
        }
        #endif
        .onReceive(logCategoryPublisher) { payload in
            logger.debug("onReceive: \(logCategoryPublisher.name.rawValue)")
            guard let categoryURI = payload.object as? URL else { return }
            router.path = [.quickLog(categoryURI)]
        }
        .onReceive(logServingPublisher) { payload in
            logger.debug("onReceive: \(logServingPublisher.name.rawValue)")
            guard let servingURI = payload.object as? URL else { return }
            router.path = [.servingRun(servingURI)]
        }
    }

    private var calorieTitle: some View {
        HStack {
            CalorieTitle()
                .foregroundColor(.accentColor)
                .fontWeight(.bold)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            router.path.append(.calorieDetail)
        }
    }

    private func categoryCell(category: MCategory, now: Binding<Date>) -> some View {
        CategoryCell(category: category,
                     now: now,
                     onDetail: {
                         detailAction($0)
                     },
                     onShortPress: {
                         categoryRunAction($0)
                     })
    }

    #if os(watchOS)
        private var todayButton: some View {
            Button(action: todayAction) {
                Label("Today", systemImage: "sun.max")
            }
        }

        private var settingsButton: some View {
            Button(action: settingsAction) {
                Label("Settings", systemImage: "gear.circle")
            }
        }

        private var aboutButton: some View {
            Button(action: aboutAction) {
                Label("About \(shortAppName)", systemImage: "info.circle")
            }
        }
    #endif

    #if os(iOS)
        private var rowBackground: some View {
            EntityBackground(.accentColor)
        }
    #endif

    // MARK: - Properties

    // MARK: - Actions

    private func detailAction(_ uri: URL) {
        logger.notice("\(#function)")
        Haptics.play()

        router.path.append(DcaltRoute.categoryDetail(uri))
    }

    private func categoryRunAction(_ uri: URL) {
        logger.notice("\(#function)")
        Haptics.play()

        router.path.append(DcaltRoute.categoryRun(uri))
    }

    private func standardCategoriesAction() {
        do {
            try MCategory.refreshStandard(viewContext)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    #if os(watchOS)
        private func todayAction() {
            logger.notice("\(#function)")
            Haptics.play()

            router.path.append(DcaltRoute.dayRunToday)
        }

        private func settingsAction() {
            logger.notice("\(#function)")
            Haptics.play()

            router.path.append(DcaltRoute.settings)
        }

        private func aboutAction() {
            logger.notice("\(#function)")
            Haptics.play()

            router.path.append(DcaltRoute.about)
        }
    #endif
}

struct CategoryList_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var navData: Data?
        var body: some View {
            DcaltNavStack(navData: $navData) {
                CategoryList()
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        let c1 = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        let c2 = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        _ = MServing.create(ctx, category: c1, userOrder: 1, name: "Pot Pie")
        _ = MServing.create(ctx, category: c2, userOrder: 1, name: "Licorice")

        return TestHolder()
            .accentColor(.green)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
