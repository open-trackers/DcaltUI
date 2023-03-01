//
//  NavTitle.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

/// A leading-justified title, currently for use on WatchOS
public struct NavTitle: View {
    private let title: String
    private let color: Color

    public init(_ title: String, color: Color = .accentColor) {
        self.title = title
        self.color = color
    }

    public var body: some View {
        HStack {
            Text(title)
                .foregroundColor(color)
            Spacer()
        }
    }
}

struct NavTitle_Previews: PreviewProvider {
    static var previews: some View {
        NavTitle("Blah")
            .accentColor(.green)
    }
}
