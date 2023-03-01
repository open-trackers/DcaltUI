//
//  CategoryCell.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

// import ColorThemeLib
import Compactor

import DcaltLib
import TrackerLib
import TrackerUI

extension MCategory: Celled {}

public struct CategoryCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Parameters

    private let category: MCategory
    @Binding private var now: Date
    private let onDetail: (URL) -> Void
    private let onShortPress: (URL) -> Void

    public init(category: MCategory,
                now: Binding<Date>,
                onDetail: @escaping (URL) -> Void,
                onShortPress: @escaping (URL) -> Void)
    {
        self.category = category
        _now = now
        self.onDetail = onDetail
        self.onShortPress = onShortPress
    }

    // MARK: - Views

    public var body: some View {
        Cell(element: category,
             now: $now,
             defaultImageName: "carrot.fill",
             subtitle: subtitle,
             onDetail: { onDetail(uri) },
             onShortPress: { onShortPress(uri) })
    }

    private func subtitle() -> some View {
        SinceText(lastCalories: category.lastCalories,
                  lastConsumedAt: category.lastConsumedAt,
                  now: $now,
                  compactorStyle: compactorStyle)
    }

    // MARK: - Properties

    private var uri: URL {
        category.uriRepresentation
    }

    private var compactorStyle: TimeCompactor.Style {
        #if os(watchOS)
            .short
        #else
            .full
        #endif
    }
}

struct CategoryCell_Previews: PreviewProvider {
    struct TestHolder: View {
        var categories: [MCategory]
        @State var now: Date = .now
        var body: some View {
            List(categories, id: \.self) { category in
                CategoryCell(category: category,
                             now: $now,
                             onDetail: { _ in },
                             onShortPress: { _ in })
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()

        let ctx = manager.container.viewContext
        let r1 = MCategory.create(ctx, userOrder: 0)
        r1.name = "Fruit & Vegetables & Cats & Dogs & Birds"
        r1.lastCalories = 1200
        r1.lastConsumedAt = Date.now.addingTimeInterval(-234_232)
        r1.setColor(.green)
        let r2 = MCategory.create(ctx, userOrder: 1)
        r2.name = "Meat & Fish"
        r2.lastCalories = 223
        r2.lastConsumedAt = Date.now.addingTimeInterval(-10000)
        // r2.setColor(color: .yellow)
        let r3 = MCategory.create(ctx, userOrder: 2)
        r3.name = "Wood"
        r3.lastCalories = 115
        r3.lastConsumedAt = Date.now.addingTimeInterval(-6422)
        r3.setColor(.red)
        return NavigationStack {
            TestHolder(categories: [r1, r2, r3])
                .environment(\.managedObjectContext, ctx)
        }
        .environment(\.managedObjectContext, ctx)
    }
}
