//
//  DcaltRoutes.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

import TrackerUI

public typealias DcaltRouter = Router<DcaltRoute>

public enum DcaltRoute: Hashable, Codable {
    case settings
    case about
    case categoryDetail(_ categoryUri: URL)
    case categoryRun(_ categoryRun: URL)
    case servingDetail(_ servingUri: URL)
    case servingList(_ categoryUri: URL)
    case servingRun(_ servingUri: URL)
    case quickLog(_ categoryUri: URL)
    case foodGroupList(_ categoryUri: URL)
    case dayRunToday // NOTE: platform-specific views
    case dayRunArchive(_ dayRunUri: URL)
    case dayRunList // History view from archive
    case servingRunDetail(_ servingRunUri: URL)

    private func uriSuffix(_ uri: URL) -> String {
        "[\(uri.absoluteString.suffix(12))]"
    }
}
