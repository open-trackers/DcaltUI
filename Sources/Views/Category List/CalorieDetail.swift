//
//  CalorieDetail.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import DcaltLib
import TrackerLib
import TrackerUI

struct CalorieDetail: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    @AppStorage(progressFormatModeKey) private var progressFormat: ProgressFormat = .defaultValue

    let isCompact = false

    var body: some View {
        platformView
            .navigationTitle(title)
            .symbolRenderingMode(.hierarchical)
    }

    #if os(watchOS)
        private var platformView: some View {
            VStack {
                Text("\(calories ?? 0) cal")
                    .font(.largeTitle)
                    .foregroundColor(caloriesColor)
                Section {
                    formatPicker
                        .pickerStyle(.wheel)
                } footer: {
                    Text("Display Format")
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            VStack {
                GroupBox {
                    Text("\(calories ?? 0) cal")
                        .font(.largeTitle)
                        .foregroundColor(caloriesColor)
                } label: {
                    Text("Today")
                }

                GroupBox {
                    Text("\(targetCalories ?? 0) cal")
                        .font(.largeTitle)
                } label: {
                    Text("Target")
                }

                GroupBox {
                    Text("\(percent ?? "?")")
                        .font(.largeTitle)
                } label: {
                    Text("Progress")
                }

                GroupBox {
                    formatPicker
                } label: {
                    Text("Display Format")
                }

                Spacer()
            }
            .padding()
        }
    #endif

    private var formatPicker: some View {
        ProgressFormatPicker(progressFormat: $progressFormat,
                             calories: calories ?? 0,
                             targetCalories: targetCalories ?? 0)
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
        "Today"
    }

    private var targetCalories: Int16? {
        appSetting?.targetCalories
    }

    private var appSetting: AppSetting? {
        try? AppSetting.getOrCreate(viewContext)
    }

    private var calories: Int16? {
        guard let subjectiveToday = appSetting?.subjectiveToday,
              let mainStore = manager.getMainStore(viewContext),
              let zdr = try? ZDayRun.getOrCreate(viewContext, consumedDay: subjectiveToday, inStore: mainStore)
        else { return nil }
        return zdr.calories
    }

    private var percent: String? {
        guard let calories,
              let targetCalories,
              targetCalories > 0
        else { return nil }

        let n = 100.0 * Float(calories) / Float(targetCalories)
        return String(format: "%0.0f%%", n)
    }
}

struct CalorieDetail_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let mainStore = manager.getMainStore(ctx)!

        let consumedToday = Date.now

        let (consumedDay1, consumedTime1) = consumedToday.splitToLocal()!

        let category1ArchiveID = UUID()
        let category2ArchiveID = UUID()
        let serving1ArchiveID = UUID()
        let serving2ArchiveID = UUID()

        let zc1 = ZCategory.create(ctx, categoryArchiveID: category1ArchiveID, categoryName: "Fruit", toStore: mainStore)
        let zc2 = ZCategory.create(ctx, categoryArchiveID: category2ArchiveID, categoryName: "Meat", toStore: mainStore)
        let zs1 = ZServing.create(ctx, zCategory: zc1, servingArchiveID: serving1ArchiveID, servingName: "Banana and other things", toStore: mainStore)
        let zs2 = ZServing.create(ctx, zCategory: zc2, servingArchiveID: serving2ArchiveID, servingName: "Steak and other things", toStore: mainStore)
        let zdr = ZDayRun.create(ctx, consumedDay: consumedDay1, calories: 2433, toStore: mainStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs1, consumedTime: consumedTime1, calories: 120, toStore: mainStore)
        _ = ZServingRun.create(ctx, zDayRun: zdr, zServing: zs2, consumedTime: consumedTime1, calories: 450, toStore: mainStore)
        try? ctx.save()

        return NavigationStack {
            CalorieDetail()
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
        }
    }
}
