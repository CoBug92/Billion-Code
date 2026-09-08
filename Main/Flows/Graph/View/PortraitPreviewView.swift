import SwiftUI
import UIKit

struct PortraitPreviewView: View {
    let personName: String
    let portrait: GraphNode.PortraitReference
    let onDismiss: () -> Void

    private let portraitImage: Image?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset = CGSize.zero
    @State private var isPresented = false
    @State private var isDismissing = false

    init(
        personName: String,
        portrait: GraphNode.PortraitReference,
        onDismiss: @escaping () -> Void
    ) {
        self.personName = personName
        self.portrait = portrait
        self.onDismiss = onDismiss
        portraitImage = Self.loadPortraitImage(resource: portrait.bundledResource)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .opacity(backgroundOpacity(containerSize: geometry.size))
                    .ignoresSafeArea()

                if let image = portraitImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: .imageCornerRadius,
                                style: .continuous
                            )
                        )
                        .shadow(
                            color: .black.opacity(.imageShadowOpacity),
                            radius: .imageShadowRadius,
                            y: .imageShadowOffset
                        )
                        .padding(.horizontal, Margin.x8)
                        .padding(.vertical, .imageVerticalInset)
                        .offset(dragOffset)
                        .scaleEffect(imageScale(containerSize: geometry.size))
                        .opacity(isPresented ? 1 : .zero)
                        .accessibilityLabel(L10n.Graph.Dossier.Portrait.label(personName))
                        .accessibilityValue(portrait.accessibilityAttribution)
                }
            }
            .overlay(alignment: .topTrailing) {
                closeButton(topInset: geometry.safeAreaInsets.top)
            }
            .overlay(alignment: .bottomLeading) {
                attribution(bottomInset: geometry.safeAreaInsets.bottom)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(dismissGesture(containerSize: geometry.size))
        }
        .presentationBackground(.clear)
        .statusBarHidden()
        .onAppear(perform: present)
    }
}

// MARK: - Layout

private extension PortraitPreviewView {
    func closeButton(topInset: CGFloat) -> some View {
        Button(action: dismissWithoutSwipe) {
            Image(systemName: AppSymbols.close)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(
                    width: .minimumTouchTarget,
                    height: .minimumTouchTarget
                )
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Graph.Dossier.close)
        .padding(.top, topInset + Margin.x4)
        .padding(.trailing, Margin.x6)
        .opacity(isPresented ? 1 : .zero)
    }

    func attribution(bottomInset: CGFloat) -> some View {
        Text(portrait.accessibilityAttribution)
            .font(.caption2)
            .foregroundStyle(.white.opacity(.attributionOpacity))
            .padding(.horizontal, Margin.x8)
            .padding(.bottom, bottomInset + Margin.x6)
            .opacity(isPresented ? 1 : .zero)
            .accessibilityHidden(true)
    }

    static func loadPortraitImage(resource: String) -> Image? {
        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: nil
            ),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        return Image(uiImage: image)
    }

    func backgroundOpacity(containerSize: CGSize) -> Double {
        guard isPresented else { return .zero }
        let progress = dragProgress(containerSize: containerSize)
        return .backgroundOpacity * Double(1 - progress)
    }

    func imageScale(containerSize: CGSize) -> CGFloat {
        guard isPresented else { return .hiddenImageScale }
        return max(
            .minimumImageScale,
            1 - dragProgress(containerSize: containerSize) * .dragScaleReduction
        )
    }

    func dragProgress(containerSize: CGSize) -> CGFloat {
        let referenceDistance = max(min(containerSize.width, containerSize.height) * 0.5, 1)
        return min(hypot(dragOffset.width, dragOffset.height) / referenceDistance, 1)
    }
}

// MARK: - Interaction

private extension PortraitPreviewView {
    func present() {
        withAnimation(reduceMotion ? nil : .smooth(duration: .presentationAnimationDuration)) {
            isPresented = true
        }
    }

    func dismissGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: .minimumDragDistance)
            .onChanged { value in
                guard !isDismissing else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isDismissing else { return }
                if PortraitSwipeDismissal.shouldDismiss(
                    translation: value.translation,
                    predictedEndTranslation: value.predictedEndTranslation
                ) {
                    dismiss(
                        exitOffset: PortraitSwipeDismissal.exitOffset(
                            translation: value.translation,
                            predictedEndTranslation: value.predictedEndTranslation,
                            distance: max(containerSize.width, containerSize.height) * .exitDistanceRatio
                        )
                    )
                } else {
                    withAnimation(reduceMotion ? nil : .spring(duration: .returnAnimationDuration)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    func dismissWithoutSwipe() {
        dismiss(exitOffset: .zero)
    }

    func dismiss(exitOffset: CGSize) {
        guard !isDismissing else { return }
        isDismissing = true

        guard !reduceMotion else {
            onDismiss()
            return
        }

        withAnimation(
            .easeOut(duration: .dismissalAnimationDuration),
            completionCriteria: .logicallyComplete
        ) {
            dragOffset = exitOffset
            isPresented = false
        } completion: {
            onDismiss()
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let dragScaleReduction = 0.18
    static let exitDistanceRatio = 1.35
    static let hiddenImageScale = 0.9
    static let imageCornerRadius = 20.0
    static let imageShadowOffset = 8.0
    static let imageShadowRadius = 28.0
    static let imageVerticalInset = 92.0
    static let minimumDragDistance = 8.0
    static let minimumImageScale = 0.82
    static let minimumTouchTarget = 44.0
}

private extension Double {
    static let attributionOpacity = 0.72
    static let backgroundOpacity = 0.94
    static let dismissalAnimationDuration = 0.22
    static let imageShadowOpacity = 0.45
    static let presentationAnimationDuration = 0.24
    static let returnAnimationDuration = 0.28
}

// MARK: - Preview

#Preview {
    let node = GraphAtlasFixture.editorial.nodes[0]
    if let portrait = node.portrait {
        PortraitPreviewView(
            personName: node.name,
            portrait: portrait,
            onDismiss: {}
        )
    }
}
