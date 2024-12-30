//
// Swipy is a SwiftUI library for making swipe actions.
//
// See the GitHub repo for documentation:
// https://github.com/rohanrhu/Swipy
//
// Copyright (C) 2024, Oğuzhan Eroğlu (https://meowingcat.io)
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import SwiftUI

public struct SwipyHorizontalMargin: Sendable {
    public let leading: Double
    public let trailing: Double

    public init(leading: Double, trailing: Double) {
        self.leading = leading
        self.trailing = trailing
    }
}

public struct SwipySwipeBehavior: Sendable {
    public typealias Decider = @MainActor @Sendable (SwipyModel, DragGesture.Value) -> Bool

    public let decider: Decider

    public init(decider: @escaping Decider) {
        self.decider = decider
    }

    public static let normal = SwipySwipeBehavior(decider: { model, gesture in
        !(!model.isSwiped && !model.isSwiping && (gesture.velocity.width > -200 || gesture.translation.width > -50))
    })

    public static let soft = SwipySwipeBehavior(decider: { model, gesture in
        !(!model.isSwiped && !model.isSwiping && (gesture.velocity.width > -100 || gesture.translation.width > -25))
    })

    public static let hard = SwipySwipeBehavior(decider: { model, gesture in
        !(!model.isSwiped && !model.isSwiping && (gesture.velocity.width > -400 || gesture.translation.width > -100))
    })

    public static let straight = SwipySwipeBehavior(decider: { _, _ in true })

    public static let disabled = SwipySwipeBehavior(decider: { _, _ in false })

    public func or(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) || combiningBehavior.decider(model, gesture)
        }
    }

    public func and(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) && combiningBehavior.decider(model, gesture)
        }
    }

    public func not(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) && !combiningBehavior.decider(model, gesture)
        }
    }

    public static func custom(_ decider: @escaping Decider = { model, _ in model.isSwiped || model.isSwiping }) -> Self {
        .init(decider: decider)
    }

    public static func swiping() -> Self {
        .init { model, _ in model.isSwiping }
    }

    public static func swiped() -> Self {
        .init { model, _ in model.isSwiped }
    }

    public static func offset(_ offset: Double) -> Self {
        .init { _, gesture in
            abs(gesture.translation.width) > offset
        }
    }

    public static func velocity(_ velocity: Double) -> Self {
        .init { _, gesture in
            abs(gesture.velocity.width) > velocity
        }
    }
}

public struct SwipyScrollBehavior: Sendable {
    public typealias Decider = @MainActor @Sendable (SwipyModel, DragGesture.Value) -> Bool

    public let decider: Decider

    public init(decider: @escaping Decider) {
        self.decider = decider
    }

    public static let normal = Self(decider: { model, gesture in
        !model.isSwiped && !model.isSwiping && abs(gesture.translation.height) > 10
    })

    public static let soft = Self(decider: { model, gesture in
        !model.isSwiped && !model.isSwiping && abs(gesture.translation.height) > 5
    })

    public static let hard = Self(decider: { model, gesture in
        !model.isSwiped && !model.isSwiping && abs(gesture.translation.height) > 20
    })

    public static let disabled = SwipyScrollBehavior(decider: { _, _ in false })

    public func or(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) || combiningBehavior.decider(model, gesture)
        }
    }

    public func and(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) && combiningBehavior.decider(model, gesture)
        }
    }

    public func not(_ combiningBehavior: Self) -> Self {
        .init { model, gesture in
            decider(model, gesture) && !combiningBehavior.decider(model, gesture)
        }
    }

    public static func custom(_ decider: @escaping Decider = { model, _ in model.isSwiped || model.isSwiping }) -> Self {
        .init(decider: decider)
    }

    public static func swiping() -> Self {
        .init { model, _ in model.isSwiping }
    }

    public static func swiped() -> Self {
        .init { model, _ in model.isSwiped }
    }

    public static func offset(_ offset: Double) -> Self {
        .init { _, gesture in
            abs(gesture.translation.height) > offset
        }
    }

    public static func velocity(_ velocity: Double) -> Self {
        .init { _, gesture in
            abs(gesture.velocity.height) > velocity
        }
    }
}

public struct SwipyDefaults {
    public static let swipeActionsMargin: SwipyHorizontalMargin = SwipyHorizontalMargin(leading: 0, trailing: 0)
    public static let swipeThreshold: @MainActor @Sendable (SwipyModel) -> Double = { $0.swipeActionsWidth }
    public static let swipeBehavior: SwipySwipeBehavior = .normal
    public static let scrollBehavior: SwipyScrollBehavior = .normal
    public static let swipeActions: @Sendable () -> EmptyView = { EmptyView() }
}

@MainActor
public class SwipyModel: ObservableObject {
    @Published public var swipeOffset: CGSize = .zero
    @Published public var isSwiping: Bool = false
    @Published public var isScrolling: Bool = false
    @Published public var isSwiped: Bool = false
    @Published public var swipeActionsWidth: Double = 0.0
    @Published public var contentSize: CGSize?

    @Published public var swipeActionsMargin = SwipyDefaults.swipeActionsMargin
    @Published public var swipeThreshold: @MainActor @Sendable (SwipyModel) -> Double = SwipyDefaults.swipeThreshold
    @Published public var swipeBehavior: SwipySwipeBehavior = SwipyDefaults.swipeBehavior
    @Published public var scrollBehavior: SwipyScrollBehavior = SwipyDefaults.scrollBehavior

    public init() {}
    
    public func swipe() {
        swipeOffset.width = -swipeThreshold(self)
        isSwiped = true
    }
    
    public func unswipe() {
        isSwiped = false
        swipeOffset = .zero
    }
}

public struct Swipy<C, A>: View where C: View, A: View {
    public let content: (SwipyModel) -> C
    public let actions: () -> A

    @Binding public var isSwipingAnItem: Bool

    @StateObject public var model: SwipyModel

    public var body: some View {
        let swipeActionsModeOffset = model.swipeActionsWidth + model.swipeActionsMargin.trailing
        let threshold = model.swipeThreshold(model)
        let swipeActionOpacity = min(threshold, abs(model.swipeOffset.width)) / threshold

        ZStack {
            content(model)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { model.contentSize = geometry.size }
                            .onChange(of: geometry.size.width) { newValue in model.contentSize?.width = newValue }
                    }
                )

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer(minLength: model.swipeActionsMargin.leading)
                    actions()
                        .frame(idealHeight: geometry.size.height)
                }
                .scaledToFit()
                .opacity(swipeActionOpacity)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { model.swipeActionsWidth = geometry.size.width }
                            .onChange(of: geometry.size.width) { newValue in model.swipeActionsWidth = newValue }
                    }
                )
                .frame(height: (model.contentSize ?? geometry.size).height)
                .offset(x: (model.contentSize ?? geometry.size).width)
            }
        }
        .environmentObject(model)
        .offset(x: !model.isSwiping && model.isSwiped ? -swipeActionsModeOffset : model.swipeOffset.width)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if model.isScrolling { return }

                    if model.scrollBehavior.decider(model, value) {
                        model.isScrolling = true
                        return
                    }

                    if !model.swipeBehavior.decider(model, value) {
                        return
                    }

                    if model.swipeOffset.width > -threshold {
                        withAnimation(.bouncy) {
                            model.isSwiped = false
                        }
                    }

                    model.isSwiping = true

                    withAnimation(.bouncy) {
                        model.swipeOffset.width = value.translation.width
                    }
                }
                .onEnded { _ in
                    model.isSwiping = false
                    model.isScrolling = false

                    if model.swipeOffset.width < -threshold {
                        withAnimation(.bouncy) {
                            model.isSwiped = true
                        }
                    }

                    withAnimation(.bouncy) {
                        model.swipeOffset = .zero
                    }
                }
        )
        .onChange(of: model.isSwiping) { newValue in
            isSwipingAnItem = newValue

            if !newValue && model.isSwiped {
                withAnimation(.bouncy) {
                    model.swipeOffset.width = -threshold
                }
            } else if newValue {
                model.isSwiped = false
                withAnimation(.bouncy) {
                    model.swipeOffset = .zero
                }
            }
        }
    }

    public init(isSwipingAnItem: Binding<Bool>,
                swipeActionsMargin: SwipyHorizontalMargin = SwipyDefaults.swipeActionsMargin,
                swipeThreshold: @escaping @MainActor @Sendable (SwipyModel) -> Double = SwipyDefaults.swipeThreshold,
                swipeBehavior: SwipySwipeBehavior = SwipyDefaults.swipeBehavior,
                scrollBehavior: SwipyScrollBehavior = SwipyDefaults.scrollBehavior,
                @ViewBuilder content: @escaping (SwipyModel) -> C,
                @ViewBuilder actions: @escaping () -> A = SwipyDefaults.swipeActions) {
        self.content = content
        self.actions = actions
        _isSwipingAnItem = isSwipingAnItem

        let model = SwipyModel()
        model.swipeActionsMargin = swipeActionsMargin
        model.swipeThreshold = swipeThreshold
        model.swipeBehavior = swipeBehavior
        model.scrollBehavior = scrollBehavior
        _model = StateObject(wrappedValue: model)
    }
}

public struct SwipyAction<C>: View where C: View {
    @EnvironmentObject public var model: SwipyModel
    
    public let content: (SwipyModel) -> C

    public var body: some View {
        VStack {
            content(model)
        }
    }

    public init(@ViewBuilder content: @escaping (SwipyModel) -> C) {
        self.content = content
    }
}

struct Preview: View {
    @State var isSwipingAnItem = false
    
    @State var items: [String] = [
        "Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7", "Item 8", "Item 9", "Item 10", "Item 11", "Item 12", "Item 13", "Item 14", "Item 15", "Item 16", "Item 17", "Item 18", "Item 19", "Item 20"
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.9), .cyan.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 50)
            .hueRotation(.degrees(isSwipingAnItem ? 45 : 0))
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isSwipingAnItem)
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(items, id: \.self) { item in
                        Swipy(isSwipingAnItem: $isSwipingAnItem, swipeActionsMargin: .init(leading: 0, trailing: 20)) { model in
                            HStack(spacing: 10) {
                                Button {
                                    withAnimation(.bouncy) {
                                        model.swipe()
                                    }
                                } label: {
                                    VStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 20))
                                    }
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(16)
                                    .foregroundColor(.black)
                                }
                                Text(item)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(16)
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal)
                        } actions: {
                            HStack {
                                SwipyAction { model in
                                    Button {
                                        withAnimation(.bouncy) {
                                            items.removeAll { $0 == item }
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 20))
                                    }
                                    .frame(maxHeight: .infinity)
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                .linearGradient(
                                                    colors: [.pink.opacity(0.8), .red.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                    .foregroundColor(.white)
                                }
                                SwipyAction { model in
                                    Button {
                                        withAnimation(.bouncy) {
                                            model.unswipe()
                                        }
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 20))
                                    }
                                    .frame(maxHeight: .infinity)
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                .linearGradient(
                                                    colors: [.mint.opacity(0.8), .blue.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                    .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .preferredColorScheme(.light)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Preview()
}
