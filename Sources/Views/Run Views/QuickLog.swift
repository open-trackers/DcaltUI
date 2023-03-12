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

// import DequeModule

import DcaltLib
import TrackerLib
import TrackerUI

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

    #if os(watchOS)
        @AppStorage(storageKeyQuickLogRecents) private var recentsDict: QuickLogRecentsDict = .init()
        private let maxRecents = 4
        private let minPresetButtonWidth: CGFloat = 70
        private let verticalSpacing: CGFloat = 3 // determined empirically
        private let stepperMaxFontSize: CGFloat = 40
        private let stepperMaxHeight: CGFloat = 50
    #elseif os(iOS)
//        private let maxRecents = 12
//        private let minPresetButtonWidth: CGFloat = 80
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { logAction(immediate: false) }) {
                        consumeText
                    }
                    .disabled(value == 0)
                }
            }
            // advertise running "'Meat' Quick Log"
            .userActivity(logCategoryActivityType,
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
                    CalorieField(value: $value)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)

                } label: {
                    Text("Serving Calories")
                        .foregroundStyle(.tint)
                }

//                GroupBox {
//                    PresetValues(values: Array(recents),
//                                 minButtonWidth: minPresetButtonWidth,
//                                 label: presetLabel,
//                                 onLongPress: logPresetAction,
//                                 onShortPress: setValueAction)
//                } label: {
//                    Text("Recent Calories")
//                        .foregroundStyle(.tint)
//                }

                Spacer()
            }
            .padding()
            .navigationTitle(title)
        }

    #endif

    #if os(watchOS)
        private var platformView: some View {
            VStack {
                Text("\(value)")
                    .font(.title2)
                    .foregroundColor(.yellow)
                NumberPad(selection: $value, range: 0 ... 10000)
                    .font(.title2)
            }
            .modify {
                if #available(iOS 16.1, watchOS 9.1, *) {
                    $0.fontDesign(.monospaced)
                } else {
                    $0.monospaced()
                }
            }
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

    private var categoryUri: URL {
        category.uriRepresentation
    }

    // MARK: - Helpers

    private func setValueAction(_ val: Int16) {
        value = max(calorieRange.lowerBound, min(calorieRange.upperBound, val))
    }

    // long press action
    private func logPresetAction(_ val: Int16) {
        logger.debug("\(#function)")
        value = val
        logAction(immediate: true)
    }

    private func logAction(immediate: Bool) {
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

            Haptics.play(immediate ? .immediateAction : .click)

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
            DcaltNavStack(navData: $navData) {
                QuickLog(category: category, lastCalories: 50)
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
