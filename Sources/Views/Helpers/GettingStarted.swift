//
//  GettingStarted.swift
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

struct GettingStarted: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var appSetting: AppSetting

    // MARK: - Locals

    @State private var createStandardCategories = true

    // MARK: - Views

    var body: some View {
        Group {
            DailyTargetStepper(targetCalories: $appSetting.targetCalories)

            Divider()

            Section {
                Toggle(isOn: $createStandardCategories) {
                    Text("Create standard categories?")
                }
            } footer: {
                Text("As an alternative, you can create your own.")
            }
        }
        .onDisappear(perform: disappearAction)
    }

    // MARK: - Properties

    // MARK: - Actions

    private func disappearAction() {
        if createStandardCategories {
            try? MCategory.refreshStandard(viewContext)
        }

        do {
            try viewContext.save()
        } catch {}
    }
}

struct GettingStarted_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let appSet = AppSetting(context: manager.container.viewContext)
        appSet.startOfDayEnum = StartOfDay.defaultValue
        appSet.targetCalories = 3000
        return NavigationStack {
            GettingStarted(appSetting: appSet)
                .accentColor(.blue)
        }
        .environment(\.managedObjectContext, manager.container.viewContext)
        .environmentObject(manager)
    }
}
