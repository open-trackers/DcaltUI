//
//  DcaltDestination.swift
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

// obtain the view for the specified route
public struct DcaltDestination: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

//    private var router: DcaltRouter
    private var route: DcaltRoute

    public init(_ route: DcaltRoute) {
//        self.router = router
        self.route = route
    }

    @AppStorage(storageKeyQuickLogRecents) private var quickLogRecents: QuickLogRecentsDict = .init()

    public var body: some View {
        switch route {
        case .settings:
            // NOTE that this is only being used for watch settings
            if let appSetting = try? AppSetting.getOrCreate(viewContext) {
                DcaltSettings(appSetting: appSetting, onRestoreToDefaults: {})
            } else {
                Text("Settings not available.")
            }
        case .about:
            aboutView
        case let .categoryDetail(categoryURI):
            if let category: MCategory = MCategory.get(viewContext, forURIRepresentation: categoryURI) {
                CategoryDetail(category: category)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Category not available to display detail.")
            }
        case let .categoryRun(categoryURI):
            if let category: MCategory = MCategory.get(viewContext, forURIRepresentation: categoryURI) {
                CategoryRun(category: category)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Category not available to display detail.")
            }
        case let .servingList(categoryURI):
            if let category: MCategory = MCategory.get(viewContext, forURIRepresentation: categoryURI) {
                ServingList(category: category)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Category not available to display serving list.")
            }
        case let .servingDetail(servingURI):
            if let serving: MServing = MServing.get(viewContext, forURIRepresentation: servingURI) {
                ServingDetail(serving: serving)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Serving not available to display detail.")
            }
        case let .servingRun(servingURI):
            if let serving: MServing = MServing.get(viewContext, forURIRepresentation: servingURI) {
                ServingRun(serving: serving)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Serving not available to run.")
            }
        case let .quickLog(categoryURI):
            if let category: MCategory = MCategory.get(viewContext, forURIRepresentation: categoryURI) {
                QuickLog(category: category, lastCalories: quickLogRecents[categoryURI]?.first)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Category not available for quick add.")
            }
        case let .foodGroupList(categoryURI):
            if let category: MCategory = MCategory.get(viewContext, forURIRepresentation: categoryURI) {
                FoodGroupList(category: category)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Category not available to display preset list.")
            }
        default:
            // routes defined by platform-specific projects should have been handled earlier
            EmptyView()
        }
    }

    private var aboutView: some View {
        AboutView(shortAppName: shortAppName,
                  websiteURL: websiteAppURL,
                  privacyURL: websitePrivacyURL,
                  termsURL: websiteTermsURL,
                  tutorialURL: websiteAppTutorialURL,
                  copyright: copyright,
                  plea: websitePlea) {
            AppIcon(name: "app_icon")
        }
    }
}
