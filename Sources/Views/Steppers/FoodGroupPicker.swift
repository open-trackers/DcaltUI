//
//  CategoryPresetsPicker.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Collections
import os
import SwiftUI

import DcaltLib

public struct FoodGroupPicker: View {
    public typealias OnSelect = (FoodGroup) -> Void

    // MARK: - Parameters

    private let foodGroups: [FoodGroup]
    @Binding private var showPresets: Bool
    private let onSelect: OnSelect

    public init(foodGroups: [FoodGroup],
                showPresets: Binding<Bool>,
                onSelect: @escaping OnSelect)
    {
        self.foodGroups = foodGroups
        _showPresets = showPresets
        self.onSelect = onSelect
    }

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(foodGroups.sorted(by: <), id: \.self) { foodGroup in
                Button {
                    onSelect(foodGroup)
                    showPresets = false
                } label: {
                    Text(foodGroup.description)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showPresets = false }
            }
        }
    }
}

struct FoodGroupPicker_Previews: PreviewProvider {
    struct TestHolder: View {
        let foodGroups: [FoodGroup] = [
            .pork,
            .beef,
            .beverage,
        ]

        @State var showPresets = false
        var body: some View {
            NavigationStack {
                FoodGroupPicker(foodGroups: foodGroups, showPresets: $showPresets) {
                    print("\(#function): Selected \($0.description)")
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
