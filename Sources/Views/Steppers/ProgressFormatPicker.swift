//
//  ProgressFormatPicker.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

public let progressFormatModeKey = "progress-format-mode-key"

enum ProgressFormat: Int, CaseIterable, CustomStringConvertible {
    case caloriesOnly = 0
    case percentOnly = 1
    case caloriesPercent = 2
    case percentCalories = 3
    case caloriesTarget = 4

    var description: String {
        switch self {
        case .caloriesOnly:
            return "\(demoCalories())"
        case .percentOnly:
            return "\(demoPercent)"
        case .caloriesPercent:
            return "\(demoCalories()) (\(demoPercent))"
        case .percentCalories:
            return "\(demoPercent) (\(demoCalories())"
        case .caloriesTarget:
            return "\(demoCalories(isCompact: true))/\(demoTarget())"
        }
    }

    private func demoCalories(isCompact: Bool = false) -> String {
        formatCalories(1500, isCompact: isCompact)
    }

    private func demoTarget(isCompact: Bool = false) -> String {
        formatCalories(2000, isCompact: isCompact)
    }

    private var demoPercent: String {
        formatPercent(0.75)
    }

    static let defaultValue: ProgressFormat = .percentCalories

    // using a NF to get group separators
    private static let nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf
    }()

    private func formatCalories(_ calories: Int16, isCompact: Bool) -> String {
        let prefix = Self.nf.string(from: calories as NSNumber) ?? ""
        return isCompact ? prefix : "\(prefix) cal"
    }

    private func formatPercent(_ n: Float) -> String {
        String(format: "%0.0f%%", n)
    }

    func render(calories: Int16, targetCalories: Int16, isCompact: Bool) -> Text {
        let compactCals: Bool = {
            if self == .caloriesTarget { return true }
            if !isCompact || self == .caloriesOnly {
                return false
            }
            return true
        }()

        let cals = formatCalories(calories, isCompact: compactCals)

        let per: String = {
            guard targetCalories > 0 else { return "" }
            let n = 100.0 * Float(calories) / Float(targetCalories)
            return formatPercent(n)
        }()

        switch self {
        case .caloriesOnly:
            return Text("\(cals)")
        case .percentOnly:
            return Text("\(per)")
        case .caloriesPercent:
            return Text("\(cals) (\(per))")
        case .percentCalories:
            return Text("\(per) (\(cals))")
        case .caloriesTarget:
            let target = formatCalories(targetCalories, isCompact: isCompact)
            return Text("\(cals)/\(target)")
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
            return .caloriesOnly
        }
    }
}

struct ProgressFormatPicker: View {
    @AppStorage(progressFormatModeKey) var formatMode: ProgressFormat = .defaultValue

    var body: some View {
        Section {
            // NOTE not defining any title, as the format string was strangely wrapping on my iPhone 12 Pro
            Picker("", selection: $formatMode) {
                ForEach(ProgressFormat.allCases, id: \.self) { mode in
                    Text(mode.description)
                }
            }
            #if !os(watchOS)
            .pickerStyle(.menu)
            #endif
        } header: {
            Text("Daily Progress Format")
        } footer: {
            Text("As seen at the top of the list of categories.")
        }
    }
}

struct CalorieDisplayPicker_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Form {
                ProgressFormatPicker()
            }
        }
    }
}
