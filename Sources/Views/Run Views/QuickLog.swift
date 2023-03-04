//
//  QuickLog.swift
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

import DequeModule

import DcaltLib
import TrackerLib
import TrackerUI

// public let quickLogID = UUID(uuidString: "3433E226-BDBF-45B5-9D5E-6BAACAA92C02")!
// public let quickLogName = "Quick Log"

public let storageKeyQuickLogRecents = "quick-log-recents"
public typealias QuickLogRecentsDict = [URL: [Int16]]

public let defaultQuickLogCalories: Int16 = 150

public struct QuickLog: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter
    @EnvironmentObject private var manager: CoreDataStack

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    // MARK: - Parameters

    @ObservedObject private var category: MCategory

    public init(category: MCategory, lastCalories: Int16?) {
        self.category = category
        let initialCalories: Int16 = {
            guard let lastCalories, lastCalories > 0
            else { return defaultQuickLogCalories }
            return lastCalories
        }()
        _value = State(initialValue: initialCalories)
    }

    // MARK: - Locals

    @State private var value: Int16

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: QuickLog.self))

    @AppStorage(storageKeyQuickLogRecents) private var recentsDict: QuickLogRecentsDict = .init()
    #if os(watchOS)
        private let maxRecents = 4
    #elseif os(iOS)
        private let maxRecents = 12
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: logAction) {
                        consumeText
                    }
                    .disabled(value == 0)
                }
            }
            .onAppear(perform: appearAction)

            // advertise running "'Meat' Quick Log"
            .userActivity(categoryQuickLogActivityType,
                          userActivityUpdate)
    }

    #if os(iOS)
        private var platformView: some View {
            ScrollView {
                GroupBox {
                    TitleText(category.wrappedName)
                } label: {
                    Text("Category")
                        .foregroundStyle(.tint)
                }

                GroupBox {
                    CalorieStepper(value: $value)
                } label: {
                    Text("Serving Calories")
                        .foregroundStyle(.tint)
                }

                GroupBox {
                    PresetValues(values: Array(recents),
                                 label: presetLabel,
                                 onLongPress: logPresetAction,
                                 onShortPress: setValueAction)
                } label: {
                    Text("Recent Calories")
                        .foregroundStyle(.tint)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(title)
        }
    #endif

    #if os(watchOS)
        private var platformView: some View {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    TitleText(category.wrappedName)
                        .foregroundColor(.yellow)
                        .frame(height: geo.size.height * 1 / 4)

                    CalorieStepper(value: $value)
                        .frame(height: geo.size.height * 1 / 4)

                    PresetValues(values: recents,
                                 minimumWidth: presetWidth(geo.size.width),
                                 label: presetLabel,
                                 onLongPress: logPresetAction,
                                 onShortPress: setValueAction)
                }
                .navigationTitle {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.primary)
                }
            }
            .ignoresSafeArea(.all, edges: [.bottom])
        }
    #endif

    private func presetLabel(_ value: Int16) -> some View {
        #if os(watchOS)
            Text("\(value)")
        #elseif os(iOS)
            Text("\(value)")
                .font(.title)
        #endif
    }

    // MARK: - Properties

    private var title: String {
        "Quick Log"
    }

    #if os(watchOS)
        private func presetWidth(_ geoWidth: CGFloat) -> CGFloat {
            let presetsPerRow: CGFloat = 2
            let fudge: CGFloat = presetsPerRow * 2
            return geoWidth / presetsPerRow - fudge
        }
    #endif

    @ViewBuilder
    private var consumeText: some View {
        #if os(watchOS)
            Text("Consume")
        #elseif os(iOS)
            if verticalSizeClass == .regular {
                Text("Consume")
            } else {
                Text("Consume \(value) cal")
            }
        #endif
    }

    private var recents: [Int16] {
        var all = ArraySlice(recentsDict[categoryUri, default: []])
        #if os(watchOS)
            all = all.prefix(maxRecents)
        #endif
        return Array(all)
    }

    private var categoryUri: URL {
        category.uriRepresentation
    }

    // MARK: - Helpers

    private func setValueAction(_ val: Int16) {
        value = max(calorieRange.lowerBound, min(calorieRange.upperBound, val))
    }

    private func updateRecents(with val: Int16) {
        recentsDict[categoryUri, default: []].updateMRU(with: val, maxCount: maxRecents)
    }

    // MARK: - Actions

    private func appearAction() {
        if recents.first == nil {
            let vals: [Int16] = [25, 50, 100, 150, 200, 400, 600, 800]
            vals.forEach { updateRecents(with: $0) }
        }
    }

    // long press action
    private func logPresetAction(_ val: Int16) {
        logger.debug("\(#function)")
        value = val
        logAction()
    }

    private func logAction() {
        logger.debug("\(#function)")

        guard let mainStore = manager.getMainStore(viewContext) else {
            logger.error("\(#function): Unable to obtain main store. Cannot create quick log.")
            return
        }

        guard let appSetting = try? AppSetting.getOrCreate(viewContext) else {
            logger.error("\(#function): Unable to obtain app settings. Cannot create quick log.")
            return
        }

        let quickLogName = "‘\(category.wrappedName)’"
        let quickLogID = category.archiveID ?? UUID()

        do {
            try MServing.logCalories(viewContext,
                                     category: category,
                                     mainStore: mainStore,
                                     servingArchiveID: quickLogID,
                                     servingName: quickLogName,
                                     netCalories: value,
                                     startOfDay: appSetting.startOfDayEnum)

            try viewContext.save()

            // update stored list of most recently used (MRU) values for the category
            updateRecents(with: value)

            Haptics.play()

            router.path.removeAll()

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - User Activity

    private func userActivityUpdate(_ userActivity: NSUserActivity) {
        logger.debug("\(#function)")

        userActivity.title = "Quick Log ‘\(category.wrappedName)’"
        userActivity.userInfo = [
            userActivity_uriRepKey: category.uriRepresentation,
        ]
        userActivity.isEligibleForPrediction = true
        userActivity.isEligibleForSearch = true
    }
}

struct QuickLog_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        @State var navData: Data?
        @State var isNew = false
        var body: some View {
            NavStack(navData: $navData) {
                QuickLog(category: category, lastCalories: 250)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Fruit"
        return TestHolder(category: category)
            .accentColor(.mint)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
