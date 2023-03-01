//
//  FooTests.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData

@testable import DcaltUI
import XCTest

final class FooTests: TestBase {
    let timestampStr = "2022-02-05T08:10:59Z"
    var timestamp: Date!

    override func setUpWithError() throws {
        try super.setUpWithError()

        timestamp = df.date(from: timestampStr)
    }

    func testTimestampFileName() throws {
        XCTAssertTrue(true)
//        let actual = generateTimestampFileName(prefix: "foo-", suffix: ".bar", timestamp: timestamp)
//        let expected = "foo-20220205081059.bar"
//        XCTAssertEqual(expected, actual)
    }
}
