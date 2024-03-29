//
//  ServingRun.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import DcaltLib
import TrackerUI

public struct ServingRun: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: DcaltRouter
    @EnvironmentObject private var manager: CoreDataStack

    // TODO: @AppStorage(logToHistoryKey) var logToHistory: Bool = true

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.colorScheme) private var colorScheme
    #endif

    // MARK: - Parameters

    @ObservedObject private var serving: MServing

    public init(serving: MServing) {
        self.serving = serving

        _intensity = State(initialValue: serving.lastIntensity)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ServingRun.self))

    @State private var intensity: Float

    private let epsilon: Float = 0.0001

    #if os(watchOS)
        private let verticalSpacing: CGFloat = 2 // determined empirically
        private let topPadding: CGFloat = 23
        private let stepperMaxFontSize: CGFloat = 40
        private let stepperMaxHeight: CGFloat = 60
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .automatic) {
                        Button(action: editAction) {
                            Text("Edit")
                        }
                    }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: logAction) {
                        consumeText
                    }
                    .disabled(intensity == 0.0)
                }
            }

            // advertise running "Log '12 oz Porterhouse'"
            .userActivity(logServingActivityType,
                          userActivityUpdate)
    }

    #if os(watchOS)
        private var slices: CGFloat = 13
        private var platformView: some View {
            GeometryReader { geo in
                VStack(spacing: verticalSpacing) {
                    Text(serving.wrappedName)
                        .font(.title3)
                        .lineLimit(1)
                        .frame(height: geo.size.height * 1 / slices)

                    Text("\(netCalories, specifier: "%0.0f") cal")
                        .font(.title)
                        .lineLimit(1)
                        .foregroundColor(.yellow)
                        .frame(height: geo.size.height * 3 / slices)

                    // TODO: refactor this into IntensityStepper, so it works on both watch and phone
                    ValueStepper(value: $intensity,
                                 in: intensityRange,
                                 step: intensityStep,
                                 specifier: "%0.0f﹪",
                                 multiplier: 100,
                                 maxFontSize: stepperMaxFontSize,
                                 forceFocus: true)
                        .frame(height: geo.size.height * 3 / slices)
//                        .frame(maxHeight: stepperMaxHeight)

                    HStack(spacing: 20) {
                        Text("\(netWeight, specifier: "%0.0f") g")
                            .foregroundColor(netWeight > 0 ? .secondary : .secondary.opacity(0.5))
                        Text("\(netVolume, specifier: "%0.0f") ml")
                            .foregroundColor(netVolume > 0 ? .secondary : .secondary.opacity(0.5))
                    }
                    .font(.title2)
                    .lineLimit(1)
                    .frame(height: geo.size.height * 3 / slices)

                    HStack(spacing: 15) {
                        Button(action: editAction) {
                            Image(systemName: "ellipsis.circle.fill")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(servingColorDarkBg)

                        intensityButtons
                            .imageScale(.large)
                            .foregroundStyle(servingColorDarkBg)
                            .font(.title3)
                    }
                    .frame(height: geo.size.height * 2 / slices)
                }
                .symbolRenderingMode(.hierarchical)
            }
            .ignoresSafeArea(.all, edges: [.bottom])
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            ScrollView {
                Text(serving.wrappedName)
                    .multilineTextAlignment(.leading)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .lineLimit(3)
                HStack {
                    GroupBox {
                        box(value: Float(serving.calories), title: "Calories", fgColor: .secondary)
                        if hasWeight {
                            box(value: serving.weight_g, units: "g", title: "Weight", fgColor: .secondary)
                        }
                        if hasVolume {
                            box(value: serving.volume_mL, units: "ml", title: "Volume", fgColor: .secondary)
                        }
                    } label: {
                        Text("Base")
                            .foregroundStyle(.tint)
                    }
                    GroupBox {
                        box(value: netCalories, title: "Calories", fgColor: .primary)
                        if hasWeight {
                            box(value: netWeight, units: "g", title: "Weight", fgColor: .primary)
                        }
                        if hasVolume {
                            box(value: netVolume, units: "ml", title: "Volume", fgColor: .primary)
                        }
                    } label: {
                        Text("Net")
                            .foregroundStyle(.tint)
                    }
                }

                intensityBox

                Spacer()
            }
            .padding()
            .navigationTitle("Serving")
            .navigationBarTitleDisplayMode(.large)
        }
    #endif

    #if os(iOS)
        private func box(value: Float,
                         units: String? = nil,
                         title: String,
                         fgColor: Color) -> some View
        {
            GroupBox {
                VStack {
                    if value != 0 {
                        Text("\(value, specifier: "%0.0f")")
                    } else {
                        Text("-")
                    }
                }
                .foregroundColor(value != 0 ? fgColor : .secondary)
                .font(.largeTitle)
                .lineLimit(1)
                .padding(.top, 1)
            } label: {
                let str = units != nil ? "\(title) (\(units!))" : title
                Text(str)
                    .foregroundStyle(.tint.opacity(value != 0 ? 1.0 : 0.5))
            }
        }
    #endif

    #if os(iOS)
        private var intensityBox: some View {
            GroupBox {
                IntensityStepper(value: $intensity, forceFocus: false)
            } label: {
                HStack {
                    Text("Serving Size")
                        .foregroundStyle(.tint)
                    Spacer()

                    intensityButtons
                        .imageScale(.large)
                        .font(.body)
                }
            }
        }
    #endif

    private func intensityButton(_ value: Float, _ systemName: String) -> some View {
        Button(action: { intensity = value }) {
            Image(systemName: systemName)
        }
        .buttonStyle(.plain)
        // .symbolRenderingMode(.hierarchical)
        .disabled(isIntensityAt(value))
    }

    @ViewBuilder
    private var intensityButtons: some View {
        intensityButton(0.5, "50.circle")
        intensityButton(1.0, "1.circle")
        intensityButton(2.0, "2.circle")
        #if os(iOS)
            intensityButton(3.0, "3.circle")
        #endif
    }

    private var titleText: some View {
        TitleText(serving.wrappedName)
            .foregroundColor(titleColor)
    }

    // MARK: - Properties

    private var hasWeight: Bool {
        serving.weight_g > 0
    }

    private var hasVolume: Bool {
        serving.volume_mL > 0
    }

    @ViewBuilder
    private var consumeText: some View {
        #if os(watchOS)
            Text("Consume")
        #elseif os(iOS)
            if verticalSizeClass == .regular {
                Text("Consume")
            } else {
                Text("Consume \(netCalories, specifier: "%0.0f") cal")
            }
        #endif
    }

    private func isIntensityAt(_ value: Float) -> Bool {
        intensity.isEqual(to: value, accuracy: epsilon)
    }

    private var netWeight: Float {
        guard serving.weight_g > 0 else { return 0 }
        return serving.weight_g * intensity
    }

    private var netVolume: Float {
        guard serving.volume_mL > 0 else { return 0 }
        return serving.volume_mL * intensity
    }

    private var baseCalories: Float {
        Float(serving.calories)
    }

    private var netCalories: Float {
        baseCalories * intensity
    }

    private var titleColor: Color {
        #if os(watchOS)
            let base = servingColorDarkBg
        #elseif os(iOS)
            let base = colorScheme == .light ? .primary : servingColorDarkBg
        #endif
        return base
    }

    // MARK: - Actions

    private func editAction() {
        logger.debug("\(#function)")
        Haptics.play()

        router.path.append(DcaltRoute.servingDetail(serving.uriRepresentation))
    }

    private func logAction() {
        logger.debug("\(#function) ENTER")

        guard let mainStore = manager.getMainStore(viewContext)
        else {
            logger.error("\(#function): Unable to obtain prerequisites to log serving.")
            return
        }

        do {
            try serving.logCalories(viewContext,
                                    mainStore: mainStore,
                                    intensity: intensity,
                                    defaultColor: .accentColor)

            try viewContext.save()

            Haptics.play()

            router.path.removeAll()

            logger.debug("\(#function) DONE")

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - User Activity

    private func userActivityUpdate(_ userActivity: NSUserActivity) {
        logger.debug("\(#function)")
        userActivity.title = "Log ‘\(serving.wrappedName)’"
        userActivity.userInfo = [
            userActivity_uriRepKey: serving.uriRepresentation,
        ]
        userActivity.isEligibleForPrediction = true
        userActivity.isEligibleForSearch = true
    }
}

struct ServingRun_Previews: PreviewProvider {
    struct TestHolder: View {
        var serving: MServing
        @State var navData: Data?
        var body: some View {
            DcaltNavStack(navData: $navData) {
                ServingRun(serving: serving)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let category = MCategory.create(ctx, userOrder: 0)
        category.name = "Fruit"
        // category.colorCode = 148
        let s1 = MServing.create(ctx, category: category, userOrder: 0)
        // s1.name = "Peach"
        s1.name = "Bananas and Cantaloupe and this and that and everything else under the sun"
        s1.calories = 1500
        s1.weight_g = 0
        s1.volume_mL = 120
//        s1.amountUnits = 55
//        s1.units = Units.grams.rawValue
        return TestHolder(serving: s1)
            .accentColor(.blue)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
