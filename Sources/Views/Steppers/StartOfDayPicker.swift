//
//  StartOfDayPicker.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import DcaltLib

public struct StartOfDayPicker: View {
    // MARK: - Parameters

    @Binding private var startOfDay: StartOfDay

    public init(startOfDay: Binding<StartOfDay>) {
        _startOfDay = startOfDay
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            Picker("Start of day", selection: $startOfDay) {
                ForEach(StartOfDay.allCases, id: \.self) {
                    Text($0.description)
                        .font(.title2)
                        .tag($0)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
            // .labelsHidden()
        } footer: {
            Text("When your day begins, in your local time. Specified in 24-hour time format.")
        }
    }
}

struct StartOfDayPicker_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var startOfDay: StartOfDay = ._0300
        var body: some View {
            Form {
                StartOfDayPicker(startOfDay: $startOfDay)
            }
        }
    }

    static var previews: some View {
        NavigationStack {
            TestHolder()
                .accentColor(.orange)
        }
    }
}
