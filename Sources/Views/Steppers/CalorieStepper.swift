//
//  CalorieStepper.swift
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

struct CalorieStepper: View {
    @Binding private var value: Int16

    init(value: Binding<Int16>) {
        _value = value
    }

    var body: some View {
        ValueStepper(value: $value,
                     in: calorieRange,
                     step: calorieStep,
                     specifier: "%d cal")
    }
}

struct CalorieStepper_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var value: Int16 = 100
        var body: some View {
            Form {
                CalorieStepper(value: $value)
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
