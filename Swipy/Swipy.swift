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
import UIKit

public struct SwipyHorizontalMargin: Sendable {
    public let leading: Double
    public let trailing: Double

    public init(leading: Double, trailing: Double) {
        self.leading = leading
        self.trailing = trailing
    }
}

public struct SwipySwipeBehavior: Sendable {
    public typealias Decider = @MainActor @Sendable (SwipyModel, CGSize, CGSize) -> Bool

    public let decider: Decider

    public init(decider: @escaping Decider) {
        self.decider = decider
    }

    public static let normal = SwipySwipeBehavior(decider: { model, translation, velocity in
        !(!model.isSwiped && !model.isSwiping && (velocity.width > -200 || translation.width > -50))
    })

    public static let soft = SwipySwipeBehavior(decider: { model, translation, velocity in
        !(!model.isSwiped && !model.isSwiping && (velocity.width > -100 || translation.width > -25))
    })

    public static let hard = SwipySwipeBehavior(decider: { model, translation, velocity in
        !(!model.isSwiped && !model.isSwiping && (velocity.width > -400 || translation.width > -100))
    })

    public static let straight = SwipySwipeBehavior(decider: { _, _, _ in true })

    public static let disabled = SwipySwipeBehavior(decider: { _, _, _ in false })

    public func or(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) || combiningBehavior.decider(model, translation, velocity)
        }
    }

    public func and(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) && combiningBehavior.decider(model, translation, velocity)
        }
    }

    public func not(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) && !combiningBehavior.decider(model, translation, velocity)
        }
    }

    public static func custom(_ decider: @escaping Decider = { model, _, _ in model.isSwiped || model.isSwiping }) -> Self {
        .init(decider: decider)
    }

    public static func swiping() -> Self {
        .init { model, _, _ in model.isSwiping }
    }

    public static func swiped() -> Self {
        .init { model, _, _ in model.isSwiped }
    }

    public static func offset(_ offset: Double) -> Self {
        .init { _, translation, _ in
            abs(translation.width) > offset
        }
    }

    public static func velocity(_ velocity: Double) -> Self {
        .init { _, _, velocityValue in
            abs(velocityValue.width) > velocity
        }
    }
}

public struct SwipyScrollBehavior: Sendable {
    public typealias Decider = @MainActor @Sendable (SwipyModel, CGSize, CGSize) -> Bool

    public let decider: Decider

    public init(decider: @escaping Decider) {
        self.decider = decider
    }

    public static let normal = Self(decider: { model, translation, _ in
        !model.isSwiped && !model.isSwiping && abs(translation.height) > 10
    })

    public static let soft = Self(decider: { model, translation, _ in
        !model.isSwiped && !model.isSwiping && abs(translation.height) > 5
    })

    public static let hard = Self(decider: { model, translation, _ in
        !model.isSwiped && !model.isSwiping && abs(translation.height) > 20
    })

    public static let disabled = SwipyScrollBehavior(decider: { _, _, _ in false })

    public func or(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) || combiningBehavior.decider(model, translation, velocity)
        }
    }

    public func and(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) && combiningBehavior.decider(model, translation, velocity)
        }
    }

    public func not(_ combiningBehavior: Self) -> Self {
        .init { model, translation, velocity in
            decider(model, translation, velocity) && !combiningBehavior.decider(model, translation, velocity)
        }
    }

    public static func custom(_ decider: @escaping Decider = { model, _, _ in model.isSwiped || model.isSwiping }) -> Self {
        .init(decider: decider)
    }

    public static func swiping() -> Self {
        .init { model, _, _ in model.isSwiping }
    }

    public static func swiped() -> Self {
        .init { model, _, _ in model.isSwiped }
    }

    public static func offset(_ offset: Double) -> Self {
        .init { _, translation, _ in
            abs(translation.height) > offset
        }
    }

    public static func velocity(_ velocity: Double) -> Self {
        .init { _, _, velocityValue in
            abs(velocityValue.height) > velocity
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

public struct SwipyTouchableDisabledStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(.clear)
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
            ZStack {
                HStack(spacing: 0) {
                    content(model)
                        .disabled(model.isSwiping || model.isSwiped)
                        .buttonStyle(SwipyTouchableDisabledStyle())
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear { model.contentSize = geometry.size }
                                    .onChange(of: geometry.size.width) { newValue in model.contentSize?.width = newValue }
                            }
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .modifier {
            if #available(iOS 18, *) {
                $0.gesture(
                    SimultaneousSwipeGesture(
                        onChanged: onSwipeChanged,
                        onEnded: onSwipeEnded
                    )
                )
            } else {
                $0.simultaneousGesture(
                    DragGesture()
                        .onChanged(onDragChanged)
                        .onEnded(onDragEnded)
                )
            }
        }
    }
    
    private func onSwipeChanged(_ recognizer: UILongPressGestureRecognizer, _ translation: CGSize, _ velocity: CGSize) {
        if model.isScrolling { return }
        
        let threshold = model.swipeThreshold(model)

        if model.scrollBehavior.decider(model, translation, velocity) {
            model.isScrolling = true
            return
        }

        if !model.swipeBehavior.decider(model, translation, velocity) {
            return
        }

        if model.swipeOffset.width > -threshold {
            withAnimation(.bouncy) {
                model.isSwiped = false
            }
        }

        model.isSwiping = true

        withAnimation(.bouncy) {
            model.swipeOffset.width = translation.width
        }
    }
    
    private func onSwipeEnded(_ recognizer: UILongPressGestureRecognizer, _ translation: CGSize, _ velocity: CGSize) {
        let threshold = model.swipeThreshold(model)
        
        model.isSwiping = false
        model.isScrolling = false

        if model.swipeOffset.width < -threshold {
            withAnimation(.bouncy) {
                model.isSwiped = true
            }
        } else {
            withAnimation(.bouncy) {
                model.swipeOffset = .zero
            }
        }
    }

    
    private func onDragChanged(_ value: DragGesture.Value) {
        if model.isScrolling { return }
        
        let threshold = model.swipeThreshold(model)
        let translation = value.translation
        let velocity = CGSize(width: value.velocity.width, height: value.velocity.height)

        if model.scrollBehavior.decider(model, translation, velocity) {
            model.isScrolling = true
            return
        }

        if !model.swipeBehavior.decider(model, translation, velocity) {
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
    
    private func onDragEnded(_ gesture: DragGesture.Value) {
        let threshold = model.swipeThreshold(model)
        
        model.isSwiping = false
        model.isScrolling = false

        if model.swipeOffset.width < -threshold {
            withAnimation(.bouncy) {
                model.isSwiped = true
            }
        } else {
            withAnimation(.bouncy) {
                model.swipeOffset = .zero
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

@available(iOS 18.0, * )
struct SimultaneousSwipeGesture: UIGestureRecognizerRepresentable {
    
    let onBegan: (UILongPressGestureRecognizer) -> Void
    let onChanged: (UILongPressGestureRecognizer, CGSize, CGSize) -> Void
    let onEnded: (UILongPressGestureRecognizer, CGSize, CGSize) -> Void

    init(
        onBegan: @escaping (UILongPressGestureRecognizer) -> Void = { _ in },
        onChanged: @escaping (UILongPressGestureRecognizer, CGSize, CGSize) -> Void = { _, _, _ in },
        onEnded: @escaping (UILongPressGestureRecognizer, CGSize, CGSize) -> Void = { _, _, _ in }
    ) {
        self.onBegan = onBegan
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gestureRecognizer = UILongPressGestureRecognizer()
        gestureRecognizer.minimumPressDuration = 0.0
        gestureRecognizer.allowableMovement = CGFloat.greatestFiniteMagnitude
        gestureRecognizer.delegate = context.coordinator
        return gestureRecognizer
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let currentTime = Date()
        let location = recognizer.location(in: recognizer.view)
        
        switch recognizer.state {
        case .began:
            context.coordinator.startLocation = location
            context.coordinator.startTime = currentTime
            context.coordinator.lastLocation = location
            context.coordinator.lastTime = currentTime
            onBegan(recognizer)
        
        case .changed:
            let translation = CGSize(
                width: location.x - context.coordinator.startLocation.x,
                height: location.y - context.coordinator.startLocation.y
            )
            let velocity = context.coordinator.getVelocity(currentLocation: location, currentTime: currentTime)
            onChanged(recognizer, translation, velocity)
            
            context.coordinator.lastLocation = location
            context.coordinator.lastTime = currentTime
        
        case .ended, .cancelled:
            let translation = CGSize(
                width: location.x - context.coordinator.startLocation.x,
                height: location.y - context.coordinator.startLocation.y
            )
            let velocity = context.coordinator.getVelocity(currentLocation: location, currentTime: currentTime)
            onEnded(recognizer, translation, velocity)
            
            context.coordinator.startLocation = .zero
            context.coordinator.startTime = Date()
            context.coordinator.lastLocation = .zero
            context.coordinator.lastTime = Date()
        
        default:
            break
        }
    }
    
    func updateUIGestureRecognizer(_ recognizer: UILongPressGestureRecognizer, context: Context) {}
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var startLocation: CGPoint = .zero
        var startTime: Date = Date()
        var lastLocation: CGPoint = .zero
        var lastTime: Date = Date()
        
        func getVelocity(currentLocation: CGPoint, currentTime: Date) -> CGSize {
            let timeDelta = currentTime.timeIntervalSince(lastTime)
            guard timeDelta > 0 else {
                return .zero
            }
            
            let deltaX = currentLocation.x - lastLocation.x
            let deltaY = currentLocation.y - lastLocation.y
            
            return CGSize(
                width: deltaX / timeDelta,
                height: deltaY / timeDelta
            )
        }
        
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

extension View {
    @ViewBuilder
    func modifier(@ViewBuilder _ transform: (Self) -> (some View)?) -> some View {
        if let view = transform(self), !(view is EmptyView) {
            view
        } else {
            self
        }
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
