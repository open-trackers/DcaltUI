//
//  UserActivityHandlers.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import DcaltLib

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
