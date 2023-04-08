//
//  DcaltSettings.swift
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

import TrackerLib
import TrackerUI

import DcaltLib

/// Settings shared by both iOS and watchOS app
public struct DcaltSettings<Content>: View
    where Content: View
{
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    // MARK: - Parameters

    @ObservedObject private var appSetting: AppSetting
    private let onRestoreToDefaults: () -> Void
    private let content: () -> Content

    public init(appSetting: AppSetting,
                onRestoreToDefaults: @escaping () -> Void = {},
                @ViewBuilder content: @escaping () -> Content = { EmptyView() })
    {
        self.appSetting = appSetting
        self.onRestoreToDefaults = onRestoreToDefaults
        self.content = content
    }

    // MARK: - Locals

    @AppStorage(progressFormatModeKey) var progressFormat: ProgressFormat = .defaultValue

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: DcaltSettings<Content>.self))

    @State private var standardCategoriesClicked = false

    // MARK: - Views

    public var body: some View {
        BaseSettingsForm(onRestoreToDefaults: resetToDefaultsAction) {
            StartOfDayPicker(startOfDay: $appSetting.startOfDayEnum)

            DailyTargetStepper(targetCalories: $appSetting.targetCalories)

            Section {
                Button(action: standardCategoriesAction) {
                    Text("Refresh now")
                        .disabled(standardCategoriesClicked)
                }
            } header: {
                Text("Standard Categories")
            } footer: {
                Text("No existing categories (or servings) will be removed.")
            }

            content()
        }
        .onDisappear(perform: refreshWidgetAction)
    }

    // MARK: - Actions

    private func resetToDefaultsAction() {
        progressFormat = ProgressFormat.defaultValue
        standardCategoriesClicked = false

        do {
            appSetting.startOfDayEnum = StartOfDay.defaultValue
            appSetting.targetCalories = defaultTargetCalories
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        onRestoreToDefaults() // continue up the chain

        refreshWidgetAction()
    }

    private func standardCategoriesAction() {
        do {
            try MCategory.refreshStandard(viewContext)
            try viewContext.save()
            standardCategoriesClicked = true
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func refreshWidgetAction() {
        guard let mainStore = manager.getMainStore(viewContext) else { return }
        WidgetEntry.refresh(viewContext, inStore: mainStore, reload: true)
    }
}

struct DcaltSettings_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let appSet = AppSetting(context: manager.container.viewContext)
        appSet.startOfDayEnum = StartOfDay.defaultValue
        return NavigationStack { DcaltSettings(appSetting: appSet,
                                               onRestoreToDefaults: {}) { EmptyView() }
                .environment(\.managedObjectContext, manager.container.viewContext)
                .environmentObject(manager)
                .accentColor(.green)
        }
    }
}
