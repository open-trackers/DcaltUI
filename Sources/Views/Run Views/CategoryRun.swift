//
//  CategoryRun.swift
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
import TrackerUI

public struct CategoryRun: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: DcaltRouter

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    // MARK: - Parameters

    private var category: MCategory

    public init(category: MCategory) {
        self.category = category
        _servings = FetchRequest<MServing>(entity: MServing.entity(),
                                           sortDescriptors: MCategory.servingSort,
                                           predicate: category.servingPredicate)
        #if os(iOS)
            let uic = UIColor(.accentColor)
            UIPageControl.appearance().currentPageIndicatorTintColor = uic
            UIPageControl.appearance().pageIndicatorTintColor = uic.withAlphaComponent(0.35)
        #endif
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: CategoryRun.self))

    @FetchRequest private var servings: FetchedResults<MServing>

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(servings, id: \.self) { serving in
                servingButton(serving)
            }
            #if os(watchOS)
                addButton
            #endif
        }
        #if os(watchOS)
        .navigationTitle {
            NavTitle(category.wrappedName)
        }
        .toolbar {
            ToolbarItem {
                Button(action: quickLogAction) {
                    Label("Quick Log", systemImage: "bolt.fill")
                }
            }
        }
        #elseif os(iOS)
        .navigationTitle(category.wrappedName)
        .toolbar {
            ToolbarItem {
                Button(action: quickLogAction) {
                    if verticalSizeClass == .regular {
                        Image(systemName: "bolt.fill")
                    } else {
                        Text("Quick Log")
                    }
                }
            }
            ToolbarItem {
                AddServingButton(category: category)
            }
        }
        #endif
    }

    #if os(watchOS)
        private var addButton: some View {
            AddServingButton(category: category)
        }
    #endif

    private func servingButton(_ serving: MServing) -> some View {
        Button(action: {}) {
            HStack {
                Text("\(serving.name ?? "unknown")")
                    .foregroundColor(servingColor)
                Spacer()
                Text("\(serving.calories) cals")
            }
        }
        .onTapGesture {
            // print("SHORT PRESS")
            servingRunAction(serving)
        }
        .simultaneousGesture(
            LongPressGesture()
                .onEnded { _ in
                    // print("LONG PRESS")
                    immediateLogAction(serving)
                }
        )
//        .highPriorityGesture(
//            TapGesture()
//                .onEnded { _ in
//                    print("SHORT PRESS 2")
//                    //servingRunAction(serving)
//                }
//        )
    }

    // MARK: - Properties

    private var servingColor: Color {
        colorScheme == .light ? servingColorLiteBg : servingColorDarkBg
    }

    // MARK: - Actions

    // based on long press at 100% of serving
    private func immediateLogAction(_ serving: MServing) {
        logger.notice("\(#function)")

        guard let mainStore = manager.getMainStore(viewContext) else { return }
        do {
            try serving.logCalories(viewContext, mainStore: mainStore)

            try viewContext.save()

            Haptics.play(.immediateAction)

            router.path.removeAll()

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func quickLogAction() {
        logger.notice("\(#function)")
        Haptics.play()

        let uri = category.uriRepresentation
        router.path.append(DcaltRoute.quickLog(uri))
    }

    private func servingRunAction(_ serving: MServing) {
        logger.notice("\(#function)")
        Haptics.play()

        let uri = serving.uriRepresentation
        router.path.append(DcaltRoute.servingRun(uri))
    }
}

struct CategoryRun_Previews: PreviewProvider {
    struct TestHolder: View {
        var category: MCategory
        @State var navData: Data?
        @State var isNew = false
        var body: some View {
            NavStack(navData: $navData) {
                CategoryRun(category: category) // , isNew: $isNew)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Fruit"
        let s1 = MServing.create(ctx, category: category, userOrder: 0)
        s1.name = "Banana"
        s1.calories = 150
        let s2 = MServing.create(ctx, category: category, userOrder: 1)
        s2.name = "Peach"
        s2.calories = 120
        let s3 = MServing.create(ctx, category: category, userOrder: 2)
        s3.name = "Pear"
        s3.calories = 110
        return TestHolder(category: category)
            .accentColor(.blue)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
