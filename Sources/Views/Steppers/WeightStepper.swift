//
//  WeightStepper.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import DcaltLib
import TrackerLib
import TrackerUI

struct WeightStepper: View {
    @Binding var value: Float
    var forceFocus: Bool = false

    var body: some View {
        ValueStepper(value: $value,
                     in: weightRange,
                     step: weightStep,
                     specifier: "%0.0f g",
                     ifZero: "0 g",
                     forceFocus: forceFocus)
    }
}

struct WeightStepper_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var value: Float = 100.0
        var body: some View {
            NavigationStack {
                Form {
                    WeightStepper(value: $value)
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
