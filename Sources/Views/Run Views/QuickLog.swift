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

import DcaltLib
import NumberPad
import TrackerLib
import TrackerUI

public struct QuickLog: View {
    @Environment(\.colorScheme) private var colorScheme
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
            else { return Self.defaultQuickLogCalories }
            return lastCalories
        }()
        config = NPIntegerConfig(initialCalories, upperBound: 20000)
    }

    // MARK: - Locals

    @ObservedObject private var config: NPIntegerConfig<Int16>

    private static let defaultQuickLogCalories: Int16 = 150
    // private let caloriesUpperBound: Int16 = 20000

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: QuickLog.self))

    // MARK: - Views

    public var body: some View {
        platformView
            .symbolRenderingMode(.hierarchical)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { logAction(immediate: false) }) {
                        consumeText
                    }
                    .disabled(config.value == 0)
                }
            }
            // advertise running "'Meat' Quick Log"
            .userActivity(logCategoryActivityType,
                          userActivityUpdate)
    }

    #if os(iOS)
        private var platformView: some View {
            VStack {
                GroupBox {
                    Text(category.wrappedName)
                        .font(.largeTitle)
                        .lineLimit(1)

                } label: {
                    Text("Category")
                        .foregroundStyle(.tint)
                }

                GroupBox {
                    Text("\(config.value ?? 0) cal")
                        .foregroundColor(caloriesColor)
                        .font(.largeTitle)
                } label: {
                    Text("Serving")
                        .foregroundStyle(.tint)
                }

                NumberPad(config: config) { _, _ in
                    Haptics.play()
                }
                .font(.largeTitle)
                .buttonStyle(.bordered)
                .foregroundStyle(Color.primary) // NOTE: colors the backspace too
                .modify {
                    if #available(iOS 16.1, watchOS 9.1, *) {
                        $0.fontDesign(.monospaced)
                    } else {
                        $0.monospaced()
                    }
                }
                .padding(.top)
                .frame(maxWidth: 300, maxHeight: 400)

                Spacer()
            }
            .padding()
            .navigationTitle(title)
        }

    #endif

    #if os(watchOS)
        private var platformView: some View {
            GeometryReader { _ in
                VStack(spacing: 3) {
                    Text("\(config.value ?? 0) cal")
                        .font(.title2)
                        .foregroundColor(caloriesColor)
                    NumberPad(config: config) { _, _ in
                        Haptics.play()
                    }
                    .font(.title2)
            
                    
                    
                    .buttonStyle(.plain)
                    .modify {
                        if #available(iOS 16.1, watchOS 9.1, *) {
                            $0.fontDesign(.monospaced)
                        } else {
                            $0.monospaced()
                        }
                    }
                }
            }
            .ignoresSafeArea(.all, edges: [.bottom])
            .navigationTitle {
                Image(systemName: "bolt.fill")
            }
            .navigationBarTitleDisplayMode(.inline)
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

    private var caloriesColor: Color {
        #if os(watchOS)
            .yellow
        #elseif os(iOS)
            colorScheme == .light ? .primary : .yellow
        #endif
    }

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
                Text("Consume \(config.value ?? 0) cal")
            }
        #endif
    }

    private var categoryUri: URL {
        category.uriRepresentation
    }

    // MARK: - Helpers

    private func logAction(immediate: Bool) {
        logger.debug("\(#function) ENTER")

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
                                     netCalories: config.value ?? 0,
                                     startOfDay: appSetting.startOfDayEnum,
                                     defaultColor: .accentColor)

            try viewContext.save()

            Haptics.play(immediate ? .immediateAction : .click)

            // NOTE: this async wrapper is a KLUDGE to fix problem where the
            // NavigationStack was NOT popping, and then the user's manual pop
            // caused "Fatal error: Can't remove more items from a collection
            // than it contains".  (Happened on iPad Mini (6th) in landscape.)
            //
            // October 2023 update: this async operation was causing a "Simultaneous
            // accesses to 0x..., but modification requires exclusive access" on my
            // iPhone 12 Pro on iOS 17.0.3, but not on simulator. Removed async for now.
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                router.path.removeAll()
//            }

            logger.debug("\(#function) DONE")
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
