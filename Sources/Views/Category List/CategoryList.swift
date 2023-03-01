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

private let storageKeyCategoryIsNewUser = "category-is-new-user"

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

    public init() {
//        #if os(iOS)
//            // let color = colorScheme == .dark ? UIColor.yellow : UIColor(Color.accentColor)
//            let color = UIColor(Color.accentColor)
//            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: color]
//            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: color]
//        #endif
    }

    // MARK: - Locals

    @AppStorage(storageKeyCategoryIsNewUser) private var isNewUser: Bool = true

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: CategoryList.self))

    @State private var showNewUser = false

    // MARK: - Views

    public var body: some View {
        CellList(cell: categoryCell,
                 addButton: { AddCategoryButton() }) {
            #if os(watchOS)
                watchButtons
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
        .sheet(isPresented: $showNewUser) {
            NavigationStack {
                if let appSetting = try? AppSetting.getOrCreate(viewContext) {
                    GettingStarted(appSetting: appSetting, show: $showNewUser)
                } else {
                    Text("Unable to retrieve settings")
                }
            }
        }
        .onContinueUserActivity(categoryQuickLogActivityType,
                                perform: categoryQuickLogContinueUserActivity)
        .task(priority: .utility, taskAction)
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
        @ViewBuilder
        private var watchButtons: some View {
            Group {
                todayButton
                addButton
                settingsButton
                aboutButton
            }
            .font(.title3)
            .tint(categoryColor)
            .foregroundStyle(.tint)
            .symbolRenderingMode(.hierarchical)
        }

        private var addButton: some View {
            AddCategoryButton()
        }

        private var todayButton: some View {
            Button(action: todayAction) {
                Label("Today", systemImage: "sun.max")
            }
        }

        private var settingsButton: some View {
            Button(action: settingsAction) {
                Label("Settings", systemImage: "gear.circle")
                    .symbolRenderingMode(.hierarchical)
            }
        }

        private var aboutButton: some View {
            Button(action: aboutAction) {
                Label(title: { Text("About") }, icon: {
                    AppIcon(name: "app_icon")
                        .frame(width: 24, height: 24)
                })
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
            showNewUser = true
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

    @Sendable
    private func taskAction() async {
        logger.notice("\(#function) START")

        await manager.container.performBackgroundTask { backgroundContext in
            do {
                #if os(watchOS)
                    // delete log records older than N days
                    guard let keepSince = Calendar.current.date(byAdding: .year, value: -1, to: Date.now),
                          let (keepSinceDay, _) = splitDate(keepSince)
                    else { throw TrackerError.missingData(msg: "Clean: could not resolve date one year in past") }
                    logger.notice("\(#function): keepSince=\(keepSinceDay)")
                    try cleanLogRecords(backgroundContext, keepSinceDay: keepSinceDay)
                #endif

                #if os(iOS)
                    guard let mainStore = manager.getMainStore(backgroundContext),
                          let archiveStore = manager.getArchiveStore(backgroundContext),
                          let startOfDay = try? AppSetting.getOrCreate(backgroundContext).startOfDayEnum
                    else {
                        logger.error("\(#function): unable to acquire configuration to transfer log records.")
                        return
                    }
                    try transferToArchive(backgroundContext,
                                          mainStore: mainStore,
                                          archiveStore: archiveStore,
                                          startOfDay: startOfDay)
                #endif

                try backgroundContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
        }
        logger.notice("\(#function) END")
    }

    // MARK: - User Activity

    private func categoryQuickLogContinueUserActivity(_ userActivity: NSUserActivity) {
        logger.notice("\(#function)")
        guard let categoryURI = userActivity.userInfo?[userActivity_uriRepKey] as? URL,
              let category = NSManagedObject.get(viewContext, forURIRepresentation: categoryURI) as? MCategory
        else {
            logger.notice("\(#function): unable to continue User Activity")
            return
        }

        logger.notice("\(#function): on category=\(category.wrappedName)")

        router.path = [.quickLog(categoryURI)]
    }

    private func categoryServingLogContinueUserActivity(_ userActivity: NSUserActivity) {
        logger.notice("\(#function)")
        guard let servingURI = userActivity.userInfo?[userActivity_uriRepKey] as? URL,
              let serving = NSManagedObject.get(viewContext, forURIRepresentation: servingURI) as? MServing
        else {
            logger.notice("\(#function): unable to continue User Activity")
            return
        }

        logger.notice("\(#function): on serving=\(serving.wrappedName)")

        router.path = [.servingRun(servingURI)]
    }
}

struct CategoryList_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var navData: Data?
        var body: some View {
            NavStack(navData: $navData) {
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
