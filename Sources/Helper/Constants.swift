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

public let categoryColor: Color = .accentColor
public let categoryColorDarkBg: Color = categoryColor.opacity(0.8)
public let categoryColorLiteBg: Color = categoryColor
public let categoryListItemTint: Color = categoryColor.opacity(0.2)

public let servingColor: Color = .yellow
public let servingColorDarkBg: Color = servingColor.opacity(0.8)
public let servingColorLiteBg: Color = .primary
public let servingListItemTint: Color = servingColor.opacity(0.2)

public let foodGroupColor: Color = .mint
public let foodGroupColorDarkBg: Color = foodGroupColor.opacity(0.8)
public let foodGroupColorLiteBg: Color = .primary
public let foodGroupListItemTint: Color = foodGroupColor.opacity(0.2)

public let defaultTargetCalories: Int16 = 2000

public let calorieRange: ClosedRange<Int16> = 0 ... 5000
public let calorieStep = Int16.Stride(1)

public let weightRange: ClosedRange<Float> = 0 ... 1000
public let weightPrecision = 1
public let weightStep: Float = 0.1

public let volumeRange: ClosedRange<Float> = 0 ... 1000
public let volumePrecision = 1
public let volumeStep: Float = 0.1

public let intensityRange: ClosedRange<Float> = 0 ... 10
public let intensityStep: Float = 0.1

public let logCategoryActivityType = "org.openalloc.dcalt.category-quick-log"
public let logServingActivityType = "org.openalloc.dcalt.category-serving-log"
public let userActivity_uriRepKey = "uriRep"

public let websiteDomain = "open-trackers.github.io"
public let copyright = "Copyright 2023 OpenAlloc LLC"

public let websiteURL = URL(string: "https://\(websiteDomain)")!
public let websitePrivacyURL = websiteURL.appending(path: "privacy")
public let websiteTermsURL = websiteURL.appending(path: "terms")

public let websiteAppURL = websiteURL.appending(path: "dct")
public let websiteAppTutorialURL = websiteAppURL.appending(path: "tutorial")

public let websitePlea: String =
    "As an open source project, we depend on our community of users. Please rate and review \(shortAppName) in the App Store!"

#if os(watchOS)
    public let shortAppName = "DCT"
#elseif os(iOS)
    public let shortAppName = "DCT+"
#endif
