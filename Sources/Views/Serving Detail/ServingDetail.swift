//
//  ServingDetail.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import DcaltLib
import TrackerUI

public struct ServingDetail: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    @ObservedObject private var serving: MServing

    public init(serving: MServing) {
        self.serving = serving
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingDetail.self))

    #if os(watchOS)
        // NOTE no longer saving the tab in scene storage, because it has been
        // annoying to not start out at the first tab when navigating to detail.
        // @SceneStorage("serving-detail-tab") private var selectedTab = 0
        @State private var selectedTab: Tab = .first

        enum Tab: Int, ControlBarProtocol {
            case name = 1
            case calories = 2
            case weight = 3
            case volume = 4

            static var first: Tab = .name
            static var last: Tab = .volume

            var previous: Tab? {
                Tab(rawValue: rawValue - 1)
            }

            var next: Tab? {
                Tab(rawValue: rawValue + 1)
            }
        }
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .accentColor(servingColor)
            .symbolRenderingMode(.hierarchical)
            .onDisappear(perform: disappearAction)
    }

    #if os(watchOS)
        private var platformView: some View {
            VStack {
                TabView(selection: $selectedTab) {
                    Form {
                        ServingName(serving: serving)
                    }
                    .tag(Tab.name)
                    Form {
                        ServingCalories(serving: serving)
                    }
                    .tag(Tab.calories)
                    Form {
                        ServingWeight(serving: serving)
                    }
                    .tag(Tab.weight)
                    Form {
                        ServingVolume(serving: serving)
                    }
                    .tag(Tab.volume)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                ControlBar(selection: $selectedTab, tint: servingColor)
                    .padding(.horizontal, 20)
                    .padding(.bottom)
            }
            .ignoresSafeArea(.all, edges: [.bottom]) // NOTE allows control bar to be at bottom
            .navigationTitle {
                NavTitle(title)
//                    .onTapGesture {
//                        withAnimation {
//                            selectedTab = .first
//                        }
//                    }
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Form {
                // FUTURE: allow user to change category

                ServingName(serving: serving)
                ServingCalories(serving: serving)

                ServingWeight(serving: serving)
                ServingVolume(serving: serving)
            }
            .navigationTitle(title)
        }
    #endif

    // MARK: - Properties

    private var servingColor: Color {
        colorScheme == .light ? servingColorLiteBg : servingColorDarkBg
    }

    private var title: String {
        "Serving"
    }

    // MARK: - Actions

    private func disappearAction() {
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct ServingDetail_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        var body: some View {
            NavigationStack {
                ServingDetail(serving: serving)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverage"
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Stout"
        serving.calories = 323
        serving.weight_g = 22
        serving.volume_mL = 13
        return TestHolder(serving: serving)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
