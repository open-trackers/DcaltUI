//
//  CalorieField.swift
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

struct CalorieField: View {
    @Binding private var value: Int16
    private let upperBound: Int16

    init(value: Binding<Int16>,
         upperBound: Int16)
    {
        _value = value
        self.upperBound = upperBound
    }

    private let nf: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        // nf.positiveSuffix = " cal"
        return nf
    }()

    var body: some View {
        TextField("Calories", value: Binding(
            get: { $value },
            set: { value = min($0.wrappedValue, upperBound) }
        ), formatter: nf)
        #if os(iOS)
            .keyboardType(.numberPad)
        #endif
//            .font(.largeTitle)
//            .multilineTextAlignment(.center)
    }
}

struct CalorieField_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var value: Int16 = 100
        var body: some View {
            Form {
                CalorieField(value: $value, upperBound: 10000)
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
