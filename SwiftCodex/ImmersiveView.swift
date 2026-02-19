//
//  ImmersiveView.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import SwiftUI
import RealityKit
import RealityKitContent
#if canImport(UIKit)
import UIKit
#endif

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var requestTextEntity = ModelEntity()
    @State private var responseTextEntity = ModelEntity()
    @State private var renderedRequestText = ""
    @State private var renderedResponseText = ""

    private let textContainerFrame = CGRect(x: 0, y: 0, width: 1.2, height: 1.1)
    private let maxDisplayedCharacterCount = 1800

    var body: some View {
        let requestDisplayText = formattedImmersiveText(
            title: "Request",
            content: appModel.lastRequestJSON,
            emptyState: "No request yet."
        )
        let responseDisplayText = formattedImmersiveText(
            title: "Response",
            content: appModel.lastResponseJSON,
            emptyState: "No response yet."
        )

        RealityView { content in
            
            configureTextEntity(
                requestTextEntity,
                at: SIMD3<Float>(-2.67, 1.05, -1.30),
                tint: .black
            )
            configureTextEntity(
                responseTextEntity,
                at: SIMD3<Float>(1.15, 1.05, -1.30),
                tint: .black
            )

            updateTextEntity(requestTextEntity, with: requestDisplayText)
            updateTextEntity(responseTextEntity, with: responseDisplayText)
            renderedRequestText = requestDisplayText
            renderedResponseText = responseDisplayText

            content.add(requestTextEntity)
            content.add(responseTextEntity)
        } update: { _ in
            if renderedRequestText != requestDisplayText {
                updateTextEntity(requestTextEntity, with: requestDisplayText)
                renderedRequestText = requestDisplayText
            }

            if renderedResponseText != responseDisplayText {
                updateTextEntity(responseTextEntity, with: responseDisplayText)
                renderedResponseText = responseDisplayText
            }
        }
    }

    private func configureTextEntity(_ entity: ModelEntity, at position: SIMD3<Float>, tint: UIColor) {
        entity.position = position
        entity.name = "immersive-text-\(position.x)"
        entity.components.set(OpacityComponent(opacity: 0.96))
        entity.components.set(BillboardComponent())
        entity.components.set(
            ModelComponent(
                mesh: MeshResource.generateText(
                    "...",
                    extrusionDepth: 0.003,
                    font: .monospacedSystemFont(ofSize: 0.055, weight: .bold),
                    containerFrame: textContainerFrame,
                    alignment: .left,
                    lineBreakMode: .byCharWrapping
                ),
                materials: [SimpleMaterial(color: tint, isMetallic: false)]
            )
        )
    }

    private func updateTextEntity(_ entity: ModelEntity, with text: String) {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.003,
            font: .monospacedSystemFont(ofSize: 0.055, weight: .bold),
            containerFrame: textContainerFrame,
            alignment: .left,
            lineBreakMode: .byCharWrapping
        )

        if let existingModel = entity.components[ModelComponent.self] {
            entity.components.set(
                ModelComponent(
                    mesh: mesh,
                    materials: existingModel.materials
                )
            )
            return
        }

        entity.components.set(
            ModelComponent(
                mesh: mesh,
                materials: [SimpleMaterial(color: .white, isMetallic: false)]
            )
        )
    }

    private func formattedImmersiveText(title: String, content: String, emptyState: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = trimmedContent.isEmpty ? emptyState : trimmedContent

        if normalizedContent.count <= maxDisplayedCharacterCount {
            return "\(title)\n\(normalizedContent)"
        }

        let cutoffIndex = normalizedContent.index(
            normalizedContent.startIndex,
            offsetBy: maxDisplayedCharacterCount
        )
        let truncated = normalizedContent[..<cutoffIndex]
        return "\(title)\n\(truncated)\n… (truncated)"
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
