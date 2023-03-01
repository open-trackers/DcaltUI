//
//  SinceText.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Combine
import SwiftUI

import Compactor

import DcaltLib

public struct SinceText: View {
    // MARK: - Parameters

    private let lastCalories: Int16?
    private let lastConsumedAt: Date?
    @Binding private var now: Date
    private let compactorStyle: TimeCompactor.Style

    public init(lastCalories: Int16?, lastConsumedAt: Date?, now: Binding<Date>, compactorStyle: TimeCompactor.Style) {
        self.lastCalories = lastCalories
        self.lastConsumedAt = lastConsumedAt
        _now = now
        self.compactorStyle = compactorStyle

        tcSince = .init(ifZero: nil, style: compactorStyle, roundSmallToWhole: true)
    }

    // MARK: - Locals

    private var tcSince: TimeCompactor

    // MARK: - Views

    public var body: some View {
        VStack {
            if let _lastStr = lastStr {
                Text(_lastStr)
            } else {
                Text("Nothing yet")
            }
        }
    }

    // MARK: - Properties

    private var lastStr: String? {
        guard let lastCalories,
              lastCalories > 0,
              let _sinceStr = sinceStr
        else { return nil }
        return "\(lastCalories) cals, \(_sinceStr) ago"
    }

    // time interval since the last workout ended, formatted compactly
    private var sinceStr: String? {
        guard let lastConsumedAt else { return nil }
        let since = max(0, now.timeIntervalSince(lastConsumedAt))
        return tcSince.string(from: since as NSNumber)
    }
}

struct SinceText_Previews: PreviewProvider {
    struct TestHolder: View {
        var lastConsumedAt = Date.now.addingTimeInterval(-2 * 86400)
        @State var now: Date = .now
        var body: some View {
            SinceText(lastCalories: 1234, lastConsumedAt: lastConsumedAt, now: $now, compactorStyle: .short)
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        return NavigationStack {
            TestHolder()
                .environment(\.managedObjectContext, ctx)
        }
    }
}
