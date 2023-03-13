//
//  CalorieTitle.swift
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

struct CalorieTitle: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Locals

    @AppStorage(progressFormatModeKey) private var progressFormat: ProgressFormat = .defaultValue

    private let remoteChangePublisher = NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)

    @State private var todayZDayRun: ZDayRun?
    @State private var refreshToggle = false

    #if os(watchOS)
        let isCompact = true
    #elseif os(iOS)
        let isCompact = false
    #endif

    var body: some View {
        Text("\(progressFormatted)\(refreshToggle ? "" : "")")
            // .foregroundStyle(isOver ? Color.red : .accentColor)
            .onAppear {
                // print("REFRESHING via onAppear")
                refreshTodayZDayRun()
            }
            .onReceive(remoteChangePublisher) { _ in
                // print("REFRESHING via Remote Change")
                refreshTodayZDayRun()
            }
    }

    private var progressFormatted: String {
        progressFormat.render(calories: todayZDayRun?.calories ?? 0,
                              targetCalories: appSetting?.targetCalories ?? 0,
                              isCompact: isCompact)
    }

    private var appSetting: AppSetting? {
        try? AppSetting.getOrCreate(viewContext)
    }

    // will show for new day if startOfDay is passed
    // uses boolean state to force refresh of Text
    // from main store (NOT archive!)
    private func refreshTodayZDayRun() {
        guard let subjectiveToday = appSetting?.subjectiveToday,
              let mainStore = manager.getMainStore(viewContext),
              let zdr = try? ZDayRun.get(viewContext, consumedDay: subjectiveToday, inStore: mainStore)
        else { return }

        zdr.updateCalories()

        do {
            try viewContext.save()
        } catch {
            return
                // logger.error("\(#function): \(error.localizedDescription)")
        }

        todayZDayRun = zdr

        refreshToggle.toggle()
    }
}

struct CalorieTitle_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext

        let c1 = MCategory.create(ctx, name: "Entrees", userOrder: 0)
        let c2 = MCategory.create(ctx, name: "Snacks", userOrder: 1)

        _ = MServing.create(ctx, category: c1, userOrder: 1, name: "Pot Pie")
        _ = MServing.create(ctx, category: c2, userOrder: 1, name: "Licorice")

        return CalorieTitle()
            .accentColor(.blue)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
