//
//  CategoryDetail.swift
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
import TrackerUI

public struct CategoryDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter

    // MARK: - Parameters

    @ObservedObject private var category: MCategory

    public init(category: MCategory) {
        self.category = category

        _color = State(initialValue: category.getColor() ?? .clear)
    }

    // MARK: - Locals

    // Using .clear as a local non-optional proxy for nil, because picker won't
    // work with optional.
    // When saved, the color .clear assigned is nil.
    @State private var color: Color

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: CategoryDetail.self))

    #if os(watchOS)
        // NOTE no longer saving the tab in scene storage, because it has been
        // annoying to not start out at the first tab when navigating to detail.
        // @SceneStorage("category-detail-tab") private var selectedTab: Int = 0
        @State private var selectedTab: Tab = .first

        enum Tab: Int, ControlBarProtocol {
            case name = 1
            case colorImage = 2
            case foodGroups = 3
            case servings = 4

            static var first: Tab = .name
            static var last: Tab = .servings

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
            .symbolRenderingMode(.hierarchical)
            .onDisappear(perform: disappearAction)
    }

    #if os(watchOS)
        private var platformView: some View {
            VStack {
                TabView(selection: $selectedTab) {
                    Form {
                        CategoryName(category: category)
                    }
                    .tag(Tab.name)

                    Form {
                        FormColorPicker(color: $color)
                        CategoryImage(category: category)
                    }
                    .tag(Tab.colorImage)

                    Form {
                        CategoryFoodGroups(category: category)
                    }
                    .tag(Tab.foodGroups)

                    FakeSection(title: "Servings") {
                        ServingList(category: category)
                    }
                    .tag(Tab.servings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                ControlBar(selection: $selectedTab, tint: categoryColor)
                    .padding(.horizontal, 20)
                    .padding(.bottom)
            }
            .ignoresSafeArea(.all, edges: [.bottom]) // NOTE allows control bar to be at bottom
            .navigationTitle {
                NavTitle(title, color: categoryColor)
                    .onTapGesture {
                        withAnimation {
                            selectedTab = .first
                        }
                    }
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Form {
                CategoryName(category: category)
                CategoryImage(category: category)
                FormColorPicker(color: $color)
                CategoryServings(category: category)
                CategoryFoodGroups(category: category)
            }
            .navigationTitle(title)
        }
    #endif

    // MARK: - Properties

    private var title: String {
        "Category"
    }

    // MARK: - Actions

    private func disappearAction() {
        do {
            category.setColor(color != .clear ? color : nil)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct CategoryDetail_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        @State var navData: Data?
        @State var isNew = false
        var body: some View {
            DcaltNavStack(navData: $navData) {
                CategoryDetail(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Beverages"
        category.setColor(.green)
        // category.colorCode = 148
        let serving = MServing.create(ctx, category: category, userOrder: 0)
        serving.name = "Latte (skim)"
        return TestHolder(category: category)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
