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
        let predicate = MServing.getPredicate(category: category)
        _servings = FetchRequest<MServing>(entity: MServing.entity(),
                                           sortDescriptors: MServing.byUserOrder(),
                                           predicate: predicate)
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

    private let listItemTint = Color.accentColor.opacity(0.2)

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(servings, id: \.self) { serving in
                servingButton(serving)
                #if os(watchOS)
                    .listItemTint(listItemTint)
                #elseif os(iOS)
                    .listRowBackground(listItemTint)
                #endif
            }
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                addButton
            #endif
        }

        #if os(watchOS)
        .navigationTitle {
            Text(category.wrappedName)
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
        HStack {
            Button(action: {}) {
                HStack {
                    Text("\(serving.name ?? "unknown")")
                        .foregroundColor(servingColor)
                        .lineLimit(3)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .onTapGesture {
                servingRunAction(serving)
            }
            .simultaneousGesture(
                LongPressGesture()
                    .onEnded { _ in
                        immediateLogAction(serving)
                    }
            )

            // NOTE: on iOS, this area needs to be outside the button so the
            // user can grab the netCalories to swipe to delete.
            netCalories(serving)
        }
    }

    private func netCalories(_ serving: MServing) -> some View {
        VStack(alignment: .trailing) {
            Text("\(serving.netCalories) cal")
                .font(.headline)
            if !serving.lastIntensityAt1 {
                Text("\(serving.lastIntensity * 100.0, specifier: "%0.0f")%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Properties

    private var servingColor: Color {
        colorScheme == .light ? servingColorLiteBg : servingColorDarkBg
    }

    // MARK: - Actions

    private func deleteAction(at offsets: IndexSet) {
        logger.notice("\(#function)")
        do {
            for index in offsets {
                let element = servings[index]
                viewContext.delete(element)
            }
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // based on long press, will log at serving.lastIntensity, which may not be 100%!
    private func immediateLogAction(_ serving: MServing) {
        logger.notice("\(#function)")

        guard let mainStore = manager.getMainStore(viewContext) else { return }
        do {
            try serving.logCalories(viewContext,
                                    mainStore: mainStore,
                                    intensity: serving.lastIntensity)

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
        var body: some View {
            DcaltNavStack(navData: $navData) {
                CategoryRun(category: category)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Fruit and Vegetables"
        let s1 = MServing.create(ctx, category: category, userOrder: 0)
        s1.name = "Banana ala King and many other things that are amazing"
        s1.calories = 150
        s1.lastIntensity = 0.75
        let s2 = MServing.create(ctx, category: category, userOrder: 1)
        s2.name = "Peach"
        s2.calories = 120
        s2.lastIntensity = 0.3
        let s3 = MServing.create(ctx, category: category, userOrder: 2)
        s3.name = "Pear"
        s3.calories = 110
        return TestHolder(category: category)
            .accentColor(.blue)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
