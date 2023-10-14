//
//  TestBase.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData

// @testable import TrackerLib
import XCTest

open class TestBase: XCTestCase {
    // public var testContainer: NSPersistentContainer!
    // public var testContext: NSManagedObjectContext!

    public lazy var df = ISO8601DateFormatter()

    override open func setUpWithError() throws {
        try super.setUpWithError()
        // testContainer = try PersistenceManager.getTestContainer()
        // testContext = testContainer.viewContext
    }
}
