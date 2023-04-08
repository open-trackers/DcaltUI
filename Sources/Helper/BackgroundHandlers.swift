//
//  BackgroundHandlers.swift
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

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                            category: "BackgroundHandlers")

public extension Notification.Name {
    static let logCategory = Notification.Name("dcalt-log-category") // payload of categoryURI
    static let logServing = Notification.Name("dcalt-log-serving") // payload of servingURI
}

public func handleLogCategoryUA(_ context: NSManagedObjectContext, _ userActivity: NSUserActivity) {
    guard let categoryURI = userActivity.userInfo?[userActivity_uriRepKey] as? URL,
          let category = MCategory.get(context, forURIRepresentation: categoryURI) as? MCategory,
          !category.isDeleted,
          category.archiveID != nil
    else {
        // logger.notice("\(#function): unable to continue User Activity")
        return
    }

    // logger.notice("\(#function): on category=\(category.wrappedName)")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NotificationCenter.default.post(name: .logCategory, object: categoryURI)
    }
}

public func handleLogServingUA(_ context: NSManagedObjectContext, _ userActivity: NSUserActivity) {
    guard let servingURI = userActivity.userInfo?[userActivity_uriRepKey] as? URL,
          let serving = MServing.get(context, forURIRepresentation: servingURI) as? MServing,
          !serving.isDeleted,
          serving.archiveID != nil
    else {
        // logger.notice("\(#function): unable to continue User Activity")
        return
    }

    // logger.notice("\(#function): on serving=\(serving.wrappedName)")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NotificationCenter.default.post(name: .logServing, object: servingURI)
    }
}

// TODO: should this be in DcaltLib?
public func handleTaskAction(_ manager: CoreDataStack) async {
    logger.notice("\(#function) START")
    await manager.container.performBackgroundTask { backgroundContext in
        do {
            // TODO: phase this out
            try updateCreatedAts(backgroundContext)
            try backgroundContext.save()

            #if os(watchOS)
                // delete log records older than one year
                guard let mainStore = manager.getMainStore(backgroundContext),
                      let keepSince = Calendar.current.date(byAdding: .year, value: -1, to: Date.now),
                      let (keepSinceDay, _) = keepSince.splitToLocal()
                else { throw TrackerError.missingData(msg: "Clean: could not resolve date one year in past") }
                logger.notice("\(#function): keepSince=\(keepSinceDay)")
                try cleanLogRecords(backgroundContext, keepSinceDay: keepSinceDay, inStore: mainStore)
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

            // ensure the widget/complication has the latest target (and day's total) calories
            refreshWidget(backgroundContext, inStore: mainStore, reload: true)

            try backgroundContext.save()

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    logger.notice("\(#function) END")
}
