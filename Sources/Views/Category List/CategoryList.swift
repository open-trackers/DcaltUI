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

extension MCategory: Named {}

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

    @AppStorage("category-is-new-user") private var isNewUser: Bool = true

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: CategoryList.self))

    @State private var showGettingStarted = false

    // MARK: - Views

    public var body: some View {
        CellList(cell: categoryCell,
                 addButton: { AddCategoryButton() })
        {
            #if os(watchOS)
                todayButton
                AddCategoryButton()
                settingsButton
                aboutButton
            #elseif os(iOS)
                EmptyView()
            #endif
        }
        #if os(watchOS)
        // .navigationBarTitleDisplayMode(.large)
        .navigationTitle {
            CalorieTitle()
                .font(.headline)
                .fontWeight(.bold)
        }
        #elseif os(iOS)
        // .navigationBarTitleDisplayMode(.inline) // reduces the space allocated
        .toolbar {
            ToolbarItem(placement: .principal) {
                CalorieTitle()
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.tint)
            }
        }
        #endif
        .onAppear(perform: appearAction)
        .sheet(isPresented: $showGettingStarted) {
            NavigationStack {
                if let appSetting = try? AppSetting.getOrCreate(viewContext) {
                    GettingStarted(appSetting: appSetting, show: $showGettingStarted)
                } else {
                    Text("Unable to retrieve settings")
                }
            }
        }
        // .task(priority: .utility, taskAction)
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

    private func appearAction() {
        // if a new user, prompt for target calories and ask if they'd like to create the standard categories
        if isNewUser {
            isNewUser = false
            showGettingStarted = true
        }
    }

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

            guard let mainStore = manager.getMainStore(viewContext),
                  let appSetting = try? AppSetting.getOrCreate(viewContext),
                  case let startOfDay = appSetting.startOfDayEnum,
                  let (consumedDay, _) = getSubjectiveDate(dayStartHour: startOfDay.hour,
                                                           dayStartMinute: startOfDay.minute),
                  let zDayRun = try? ZDayRun.get(viewContext, consumedDay: consumedDay, inStore: mainStore)
            else { return }
            router.path.append(DcaltRoute.dayRunDetail(zDayRun.uriRepresentation))
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

    // MARK: - Background Task

//    @Sendable
//    private func taskAction() async {
//        logger.notice("\(#function) START")
//
//
//        logger.notice("\(#function) END")
//    }
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
            .accentColor(.blue)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
