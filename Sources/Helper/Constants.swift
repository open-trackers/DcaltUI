//
//  Constants.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

// public let defaultDayStartHour: Int16 = 3
// public let defaultDayStartMinute: Int16 = 0
public let defaultTargetCalories: Int16 = 2000

public let calorieRange: ClosedRange<Int16> = 0 ... 2000
public let calorieStep = Int16.Stride(1)

public let weightRange: ClosedRange<Float> = 0 ... 1000
public let weightStep: Float = 1

public let volumeRange: ClosedRange<Float> = 0 ... 1000
public let volumeStep: Float = 1

public let intensityRange: ClosedRange<Float> = 0 ... 10
public let intensityStep: Float = 0.1

public let categoryColor: Color = .accentColor
public let categoryColorDarkBg: Color = categoryColor.opacity(0.8)
public let categoryColorLiteBg: Color = categoryColor

public let servingColorDarkBg: Color = .yellow.opacity(0.8)
public let servingColorLiteBg: Color = .primary
public let servingListItemTint: Color = .yellow.opacity(0.2)

public let foodGroupColorDarkBg: Color = .mint.opacity(0.8)
public let foodGroupColorLiteBg: Color = .primary
public let foodGroupListItemTint: Color = .mint.opacity(0.2)

public let websiteDomain = "daily-calorie-tracker.github.io"
public let websiteTitle = "Daily Calorie Tracker"
public let copyright = "Copyright 2023 OpenAlloc LLC"

public let websiteURL = URL(string: "https://\(websiteDomain)")!
public let websitePrivacyURL = websiteURL.appending(path: "privacy")
public let websiteTermsURL = websiteURL.appending(path: "terms")
public let websiteTutorialURL = websiteURL.appending(path: "tutorial")

public let categoryQuickLogActivityType = "org.openalloc.dcalt.category-quick-log"
public let categoryServingLogActivityType = "org.openalloc.dcalt.category-serving-log"
public let userActivity_uriRepKey = "uriRep"
