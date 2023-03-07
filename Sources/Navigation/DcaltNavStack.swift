//
//  DcaltNavStack.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import DcaltLib
import TrackerUI

public struct DcaltNavStack<Destination, Content>: View
    where Destination: View, Content: View
{
    @EnvironmentObject private var manager: CoreDataStack

    // MARK: - Parameters

    @Binding private var navData: Data?
    private var destination: (DcaltRouter, DcaltRoute) -> Destination
    private var content: () -> Content

    public init(navData: Binding<Data?>,
                @ViewBuilder destination: @escaping (DcaltRouter, DcaltRoute) -> Destination = { DcaltDestination($1).environmentObject($0) },
                @ViewBuilder content: @escaping () -> Content)
    {
        _navData = navData
        self.destination = destination
        self.content = content
    }

    public var body: some View {
        BaseNavStack(navData: $navData,
                     coreDataStack: manager,
                     destination: destination,
                     content: content)
            .environmentObject(manager)
    }
}
