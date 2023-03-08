//
//  ProgressFormat.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

public let progressFormatModeKey = "progress-format-mode-key"

enum ProgressFormat: Int, CaseIterable {
    case caloriesOnly = 0
    case percentOnly = 1
    case caloriesPercent = 2
    case percentCalories = 3
    case caloriesTarget = 4
    case remaining = 5

    static let defaultValue: ProgressFormat = .percentCalories

    func render(calories: Int16, targetCalories: Int16, isCompact: Bool) -> Text {
        var percent: String {
            guard targetCalories > 0 else { return "" }
            let n = 100.0 * Float(calories) / Float(targetCalories)
            return String(format: "%0.0f%%", n)
        }

        let cal = " cal"

        switch self {
        case .caloriesOnly:
            return Text("\(calories)\(cal)")
        case .percentOnly:
            return Text("\(percent)")
        case .caloriesPercent:
            let suffix = isCompact ? "" : cal
            return Text("\(calories)\(suffix) (\(percent))")
        case .percentCalories:
            let suffix = isCompact ? "" : cal
            return Text("\(percent) (\(calories)\(suffix))")
        case .caloriesTarget:
            let suffix = isCompact ? "" : cal
            return Text("\(calories)/\(targetCalories)\(suffix)")
        case .remaining:
            let remaining = targetCalories - calories
            if remaining >= 0 {
                let suffix = isCompact ? "remain" : "remaining"
                return Text("\(remaining) \(suffix)")
            } else {
                return Text("Over by \(-remaining)")
            }
        }
    }

    var next: ProgressFormat {
        switch self {
        case .caloriesOnly:
            return .percentOnly
        case .percentOnly:
            return .caloriesPercent
        case .caloriesPercent:
            return .percentCalories
        case .percentCalories:
            return .caloriesTarget
        case .caloriesTarget:
            return .remaining
        case .remaining:
            return .caloriesOnly
        }
    }
}
