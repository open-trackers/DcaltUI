//
//  WidgetView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import Compactor

import DcaltLib

public struct WidgetView: View {
    var entry: Provider.Entry

    public init(entry: Provider.Entry) {
        self.entry = entry
    }

    static let tc = NumberCompactor(ifZero: "0", roundSmallToWhole: true)

    public var body: some View {
        ProgressView(value: percent) {
            Text("\(Self.tc.string(from: remaining as NSNumber) ?? "")")
                .foregroundColor(remaining >= 0 ? .primary : .red)
                .padding()
                .font(.headline.bold())
//                .font(.system(size: 500))
//                .minimumScaleFactor(0.01)
        }
        .progressViewStyle(.circular)
        .tint(.accentColor)
    }

    private var remaining: Int {
        entry.targetCalories - entry.currentCalories // may be negative
    }

    private var percent: Float {
        guard entry.targetCalories > 0 else { return 0 }
        return Float(entry.currentCalories) / Float(entry.targetCalories)
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let entry = SimpleEntry(targetCalories: 2000, currentCalories: 500)
        return WidgetView(entry: entry)
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
