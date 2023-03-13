//
//  VolumeStepper.swift
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

struct VolumeStepper: View {
    @Binding private var value: Float

    init(value: Binding<Float>) {
        _value = value
    }

    var body: some View {
        ValueStepper(value: $value,
                     in: volumeRange,
                     step: volumeStep,
                     specifier: "%0.0f ml",
                     ifZero: "0 ml")
    }
}

struct VolumeStepper_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var value: Float = 1
        var body: some View {
            NavigationStack {
                Form {
                    VolumeStepper(value: $value)
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
