//
//  ImmersiveView.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var requestTextEntity = Entity()
    @State private var responseTextEntity = Entity()
    @State private var requestTextInteractionEntity = Entity()
    @State private var responseTextInteractionEntity = Entity()

    private let responsePanelWidthPoints: CGFloat = 2940
    private let requestPanelWidthPoints: CGFloat = 784
    private let requestPanelHeightPoints: CGFloat = 483
    private let responseMinimumPanelHeightPoints: CGFloat = 1800
    private let responseMaximumPanelHeightPoints: CGFloat = 6000
    private let responseEstimatedCharactersPerLine = 86
    private let responseEstimatedLineHeightPoints: CGFloat = 20
    private let responseVerticalPaddingPoints: CGFloat = 120
    private let requestManipulationHandleSize = SIMD3<Float>(0.72, 0.18, 0.30)
    private let responseManipulationHandleSize = SIMD3<Float>(2.16, 0.54, 0.90)
    private let panelContentPaddingPoints: CGFloat = 20
    private let panelDragHandleWidthPoints: CGFloat = 220
    private let panelDragHandleHeightPoints: CGFloat = 14
    private let requestPanelAnchorPosition = SIMD3<Float>(-1.60, 1.05, -1.10)
    private let responsePanelAnchorPosition = SIMD3<Float>(1.60, 1.05, -1.10)

    var body: some View {
        let requestDisplayText = formattedImmersiveText(
            content: appModel.lastRequestJSON,
            emptyState: "No request yet."
        )
        let responseDisplayText = formattedImmersiveText(
            content: appModel.lastResponseJSON,
            emptyState: "No response yet."
        )
        let responsePanelHeightPoints = dynamicResponsePanelHeight(for: responseDisplayText)

        RealityView { content in
            configureTextEntity(
                requestTextEntity,
                title: "Request",
                content: requestDisplayText,
                panelWidthPoints: requestPanelWidthPoints,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureTextEntity(
                responseTextEntity,
                title: "Response",
                content: responseDisplayText,
                panelWidthPoints: responsePanelWidthPoints,
                panelHeightPoints: responsePanelHeightPoints
            )
            configureInteractionEntity(
                requestTextInteractionEntity,
                at: requestPanelAnchorPosition,
                textEntity: requestTextEntity,
                textContent: requestDisplayText,
                manipulationHandleSize: requestManipulationHandleSize,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureInteractionEntity(
                responseTextInteractionEntity,
                at: responsePanelAnchorPosition,
                textEntity: responseTextEntity,
                textContent: responseDisplayText,
                manipulationHandleSize: responseManipulationHandleSize,
                panelHeightPoints: responsePanelHeightPoints
            )

            if requestTextInteractionEntity.parent == nil {
                content.add(requestTextInteractionEntity)
            }

            if responseTextInteractionEntity.parent == nil {
                content.add(responseTextInteractionEntity)
            }
        } update: { _ in
            configureTextEntity(
                requestTextEntity,
                title: "Request",
                content: requestDisplayText,
                panelWidthPoints: requestPanelWidthPoints,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureTextEntity(
                responseTextEntity,
                title: "Response",
                content: responseDisplayText,
                panelWidthPoints: responsePanelWidthPoints,
                panelHeightPoints: responsePanelHeightPoints
            )
            configureInteractionEntity(
                requestTextInteractionEntity,
                at: requestPanelAnchorPosition,
                textEntity: requestTextEntity,
                textContent: requestDisplayText,
                manipulationHandleSize: requestManipulationHandleSize,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureInteractionEntity(
                responseTextInteractionEntity,
                at: responsePanelAnchorPosition,
                textEntity: responseTextEntity,
                textContent: responseDisplayText,
                manipulationHandleSize: responseManipulationHandleSize,
                panelHeightPoints: responsePanelHeightPoints
            )
        }
    }

    private func configureTextEntity(
        _ entity: Entity,
        title: String,
        content: String,
        panelWidthPoints: CGFloat,
        panelHeightPoints: CGFloat
    ) {
        let newSnapshot = ImmersiveTextSnapshotComponent(
            title: title,
            content: content,
            panelWidthPoints: panelWidthPoints,
            panelHeightPoints: panelHeightPoints
        )
        if entity.components[ImmersiveTextSnapshotComponent.self] == newSnapshot {
            return
        }

        if entity.name.isEmpty {
            entity.name = "immersive-text-attachment"
        }
        entity.components.set(newSnapshot)
        entity.components.set(BillboardComponent())
        entity.components.set(OpacityComponent(opacity: 1.0))
        entity.components.set(
            ViewAttachmentComponent(
                rootView: ImmersiveTextAttachmentView(
                    title: title,
                    content: content,
                    panelWidthPoints: panelWidthPoints,
                    panelHeightPoints: panelHeightPoints,
                    contentPaddingPoints: panelContentPaddingPoints,
                    dragHandleWidthPoints: panelDragHandleWidthPoints,
                    dragHandleHeightPoints: panelDragHandleHeightPoints
                )
            )
        )
    }

    private func configureInteractionEntity(
        _ interactionEntity: Entity,
        at position: SIMD3<Float>,
        textEntity: Entity,
        textContent: String,
        manipulationHandleSize: SIMD3<Float>,
        panelHeightPoints: CGFloat
    ) {
        let interactionSnapshot = ImmersiveInteractionSnapshotComponent(
            textHash: textContent.hashValue,
            panelHeightPoints: panelHeightPoints,
            manipulationHandleSize: manipulationHandleSize
        )
        let needsCollisionRefresh = interactionEntity.components[ImmersiveInteractionSnapshotComponent.self] != interactionSnapshot

        if interactionEntity.parent == nil {
            interactionEntity.position = position
        }

        if interactionEntity.parent == nil || needsCollisionRefresh {
            interactionEntity.components.set(
                CollisionComponent(
                    shapes: [ShapeResource.generateBox(size: manipulationHandleSize)]
                )
            )
            interactionEntity.components.set(InputTargetComponent())
            interactionEntity.components.set(ManipulationComponent())
            interactionEntity.components.set(interactionSnapshot)
        }

        if textEntity.parent !== interactionEntity {
            interactionEntity.addChild(textEntity)
        }

        textEntity.position = textOffsetFromTopCenter(
            textEntity: textEntity,
            fallbackPanelHeightPoints: panelHeightPoints
        )
    }

    private func textOffsetFromTopCenter(
        textEntity _: Entity,
        fallbackPanelHeightPoints: CGFloat
    ) -> SIMD3<Float> {
        let dragHandleCenterOffsetPoints = panelContentPaddingPoints + (panelDragHandleHeightPoints * 0.5)

        // Keep the mapping deterministic on every text update so the collision center
        // (interaction entity origin) stays aligned with the drag handle center.
        let panelHeightMeters = Float(fallbackPanelHeightPoints) / 1_200.0
        let metersPerPoint = panelHeightMeters / Float(fallbackPanelHeightPoints)
        let dragHandleCenterOffsetMeters = Float(dragHandleCenterOffsetPoints) * metersPerPoint
        return SIMD3<Float>(0, (-panelHeightMeters * 0.5) + dragHandleCenterOffsetMeters, 0)
    }

    private func dynamicResponsePanelHeight(for responseText: String) -> CGFloat {
        let lineCount = estimatedWrappedLineCount(
            for: responseText,
            estimatedCharactersPerLine: responseEstimatedCharactersPerLine
        )

        let estimatedHeight = (CGFloat(lineCount) * responseEstimatedLineHeightPoints) + responseVerticalPaddingPoints
        return min(responseMaximumPanelHeightPoints, max(responseMinimumPanelHeightPoints, estimatedHeight))
    }

    private func estimatedWrappedLineCount(for text: String, estimatedCharactersPerLine: Int) -> Int {
        let hardLineCount = text.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            let characterCount = max(1, line.count)
            return Int(ceil(Double(characterCount) / Double(estimatedCharactersPerLine)))
        }

        return max(1, hardLineCount.reduce(0, +))
    }

    private func formattedImmersiveText(content: String, emptyState: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedContent.isEmpty ? emptyState : trimmedContent
    }
}

private struct ImmersiveTextSnapshotComponent: Component, Equatable {
    let title: String
    let content: String
    let panelWidthPoints: CGFloat
    let panelHeightPoints: CGFloat
}

private struct ImmersiveInteractionSnapshotComponent: Component, Equatable {
    let textHash: Int
    let panelHeightPoints: CGFloat
    let manipulationHandleSize: SIMD3<Float>
}

private struct ImmersiveTextAttachmentView: View {
    let title: String
    let content: String
    let panelWidthPoints: CGFloat
    let panelHeightPoints: CGFloat
    let contentPaddingPoints: CGFloat
    let dragHandleWidthPoints: CGFloat
    let dragHandleHeightPoints: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(.white.opacity(0.92))
                .frame(width: dragHandleWidthPoints, height: dragHandleHeightPoints)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text(content)
                .font(.system(size: 20, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(contentPaddingPoints)
        .frame(width: panelWidthPoints, height: panelHeightPoints, alignment: .topLeading)
        .background(Color.black.opacity(0.50), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
