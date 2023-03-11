//
//  DailyTargetStepper.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

struct DailyTargetStepper: View {
    @Binding var targetCalories: Int16

    var body: some View {
        Section {
            Stepper(value: $targetCalories, in: 0 ... 10000, step: 10) {
                Text("\(targetCalories) cal")
                #if os(watchOS)
                    .font(.headline)
                    .allowsTightening(true)
                    .modify {
                        if #available(iOS 16.1, watchOS 9.1, *) {
                            $0.fontDesign(.rounded)
                        } else {
                            $0
                        }
                    }
                #endif
            }
        } header: {
            Text("Daily Target")
        } footer: {
            Text("Do your research (or consult your doctor) to find the right daily target for you.")
        }
    }
}

struct DailyTargetStepper_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            DailyTargetStepper(targetCalories: .constant(2000))
        }
    }
}
