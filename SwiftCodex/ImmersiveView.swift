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

    private let panelWidthPoints: CGFloat = 980
    private let requestPanelHeightPoints: CGFloat = 420
    private let responseMinimumPanelHeightPoints: CGFloat = 1800
    private let responseMaximumPanelHeightPoints: CGFloat = 6000
    private let responseEstimatedCharactersPerLine = 86
    private let responseEstimatedLineHeightPoints: CGFloat = 20
    private let responseVerticalPaddingPoints: CGFloat = 120
    private let manipulationHandleSize = SIMD3<Float>(0.72, 0.18, 0.30)
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
                panelHeightPoints: requestPanelHeightPoints
            )
            configureTextEntity(
                responseTextEntity,
                title: "Response",
                content: responseDisplayText,
                panelHeightPoints: responsePanelHeightPoints
            )
            configureInteractionEntity(
                requestTextInteractionEntity,
                at: requestPanelAnchorPosition,
                textEntity: requestTextEntity,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureInteractionEntity(
                responseTextInteractionEntity,
                at: responsePanelAnchorPosition,
                textEntity: responseTextEntity,
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
                panelHeightPoints: requestPanelHeightPoints
            )
            configureTextEntity(
                responseTextEntity,
                title: "Response",
                content: responseDisplayText,
                panelHeightPoints: responsePanelHeightPoints
            )
            configureInteractionEntity(
                requestTextInteractionEntity,
                at: requestPanelAnchorPosition,
                textEntity: requestTextEntity,
                panelHeightPoints: requestPanelHeightPoints
            )
            configureInteractionEntity(
                responseTextInteractionEntity,
                at: responsePanelAnchorPosition,
                textEntity: responseTextEntity,
                panelHeightPoints: responsePanelHeightPoints
            )
        }
    }

    private func configureTextEntity(
        _ entity: Entity,
        title: String,
        content: String,
        panelHeightPoints: CGFloat
    ) {
        let newSnapshot = ImmersiveTextSnapshotComponent(
            title: title,
            content: content,
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
        panelHeightPoints: CGFloat
    ) {
        if interactionEntity.parent == nil {
            interactionEntity.position = position
            interactionEntity.components.set(
                CollisionComponent(
                    shapes: [ShapeResource.generateBox(size: manipulationHandleSize)]
                )
            )
            interactionEntity.components.set(InputTargetComponent())
            interactionEntity.components.set(ManipulationComponent())
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
        textEntity: Entity,
        fallbackPanelHeightPoints: CGFloat
    ) -> SIMD3<Float> {
        if let attachment = textEntity.components[ViewAttachmentComponent.self] {
            let panelHeightMeters = attachment.bounds.extents.y
            if panelHeightMeters > 0 {
                return SIMD3<Float>(0, -panelHeightMeters * 0.5, 0)
            }
        }

        // Temporary fallback before bounds become available.
        let fallbackPanelHeightMeters = Float(fallbackPanelHeightPoints) / 1_200.0
        return SIMD3<Float>(0, -fallbackPanelHeightMeters * 0.5, 0)
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
    let panelHeightPoints: CGFloat
}

private struct ImmersiveTextAttachmentView: View {
    let title: String
    let content: String
    let panelWidthPoints: CGFloat
    let panelHeightPoints: CGFloat
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
        .padding(20)
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
