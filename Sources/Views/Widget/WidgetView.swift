//
//  WidgetView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Compactor
import SwiftUI

import DcaltLib

public struct WidgetView: View {
    // MARK: - Parameters

    private let entry: Provider.Entry

    public init(entry: Provider.Entry) {
        self.entry = entry
    }

    // MARK: - Locals

    private static let tc = NumberCompactor(ifZero: "0", roundSmallToWhole: true)

    // MARK: - Views

    public var body: some View {
        #if os(watchOS)
            gauge
        #elseif os(iOS)
            Section {
                gauge
            } header: {
                Text("Daily Calories")
                    .foregroundColor(.secondary)
            }
        #endif
    }

    private var gauge: some View {
        Gauge(value: percent, in: 0.0 ... 1.0) {
            Text("CAL")
                .foregroundColor(isOver ? .red : .primary)
        } currentValueLabel: {
            Text(caloriesStr)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Gradient(colors: colors))
    }

    // MARK: - Properties

    private var caloriesStr: String {
        Self.tc.string(from: entry.currentCalories as NSNumber) ?? ""
    }

    private var colors: [Color] {
        let c = entry.pairs.map(\.color)
        return c.first == nil ? [.accentColor] : c
    }

//    private var remaining: Int {
//        entry.targetCalories - entry.currentCalories // may be negative
//    }

    private var isOver: Bool {
        entry.targetCalories < entry.currentCalories
    }

    private var percent: Float {
        guard entry.targetCalories > 0 else { return 0 }
        return Float(entry.currentCalories) / Float(entry.targetCalories)
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let entry = WidgetEntry(targetCalories: 2000, currentCalories: 500)
        return WidgetView(entry: entry)
            .accentColor(.blue)
        // .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
