//
//  ContentView.swift
//  SwiftCodex
//
//  Created by IVAN CAMPOS on 2/18/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    @State private var endpointFilter = ""
    @State private var selectedLogID: EndpointLogEntry.ID?

    private var endpointColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 10)]
    }

    private var filteredEndpoints: [AppServerMethod] {
        let query = endpointFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else {
            return AppServerMethod.allCases
        }

        return AppServerMethod.allCases.filter { method in
            method.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedLogEntry: EndpointLogEntry? {
        guard let selectedLogID else { return nil }
        return appModel.logs.first(where: { $0.id == selectedLogID })
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 14) {
                heroHeader
                controlsCard
                contentGrid
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.10),
                Color.cyan.opacity(0.06),
                Color.gray.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var heroHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Codex App-Server Harness")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))

                Text("Connect over WebSocket to run endpoint probes and inspect JSON-RPC requests, responses, and notifications in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 9, height: 9)

                Text(connectionStatusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(connectionStatusColor.opacity(0.45), lineWidth: 1)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.40), lineWidth: 1)
        }
    }

    private var controlsCard: some View {
        HStack(spacing: 10) {
            Label("Server", systemImage: "network")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("ws://10.0.0.8:4500", text: Bindable(appModel).webSocketURL)
                .textFieldStyle(.plain)
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            Button(appModel.isEndpointConnected ? "Disconnect" : "Connect") {
                Task { @MainActor in
                    if appModel.isEndpointConnected {
                        appModel.disconnectEndpointClient()
                    } else {
                        await appModel.connectEndpointWebSocket()
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Clear Log") {
                appModel.clearEndpointLogs()
            }
            .buttonStyle(.bordered)

            Spacer()

            ToggleImmersiveSpaceButton()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.32), lineWidth: 1)
        }
    }

    private var contentGrid: some View {
        HStack(alignment: .top, spacing: 14) {
            endpointsCard
            inspectorStack
        }
    }

    private var endpointsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Endpoints")
                    .font(.title3.weight(.semibold))

                Text("\(filteredEndpoints.count) of \(AppServerMethod.allCases.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())

                Spacer()

                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Filter", text: $endpointFilter)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: 240)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            LazyVGrid(columns: endpointColumns, spacing: 10) {
                ForEach(filteredEndpoints, id: \.rawValue) { method in
                    endpointButton(method)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            if filteredEndpoints.isEmpty {
                Text("No endpoint matches your filter.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 540, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.30), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func endpointButton(_ method: AppServerMethod) -> some View {
        let isSelected = appModel.selectedEndpoint == method

        Button {
            Task { @MainActor in
                await appModel.invokeEndpoint(method)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(endpointGroupName(for: method))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(method.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.20) : Color.white.opacity(0.22))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.70) : Color.white.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var inspectorStack: some View {
        VStack(alignment: .leading, spacing: 14) {
            requestResponseCard
            activityCard
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var requestResponseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request + Response")
                .font(.title3.weight(.semibold))

            HStack(alignment: .top, spacing: 10) {
                jsonPanel(title: "Request", content: appModel.lastRequestJSON, emptyState: "No request yet.")
                jsonPanel(title: "Response", content: appModel.lastResponseJSON, emptyState: "No response yet.")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 360, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.30), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func jsonPanel(title: String, content: String, emptyState: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            ScrollView {
                Text(content.isEmpty ? emptyState : content)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(content.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.title3.weight(.semibold))

                Text("\(appModel.logs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())

                Spacer()

                if let selectedLogEntry {
                    Text(selectedLogEntry.method)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(appModel.logs.reversed())) { entry in
                            logRow(entry)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxWidth: .infinity, minHeight: 210, maxHeight: 300)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Entry")
                        .font(.subheadline.weight(.semibold))

                    ScrollView {
                        Text(selectedLogEntry?.responseJSON ?? "Select an activity row to inspect payload details.")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(selectedLogEntry == nil ? .secondary : .primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 210, maxHeight: 300)
                    .background(Color.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 350, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.30), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func logRow(_ entry: EndpointLogEntry) -> some View {
        let isSelected = selectedLogID == entry.id

        Button {
            selectedLogID = entry.id
            lastResponseSelectionFallback(for: entry)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(entry.success ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(timestampString(entry.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(entry.kind.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if let latency = entry.latencyMs {
                            Text("\(latency) ms")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(entry.method)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(entry.responseJSON)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.16) : Color.white.opacity(0.16))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.70) : Color.white.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func lastResponseSelectionFallback(for entry: EndpointLogEntry) {
        if appModel.lastResponseJSON.isEmpty {
            appModel.lastResponseJSON = entry.responseJSON
        }

        if appModel.lastRequestJSON.isEmpty == false {
            return
        }

        if entry.requestJSON.isEmpty == false {
            appModel.lastRequestJSON = entry.requestJSON
        }
    }

    private var connectionStatusText: String {
        switch appModel.connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return appModel.isInitialized ? "Connected + Initialized" : "Connected"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }

    private var connectionStatusColor: Color {
        switch appModel.connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .failed:
            return .red
        }
    }

    private func endpointGroupName(for method: AppServerMethod) -> String {
        let prefix = method.rawValue.split(separator: "/").first ?? Substring(method.rawValue)

        switch prefix {
        case "initialize":
            return "Lifecycle"
        case "thread":
            return "Thread"
        case "turn":
            return "Turn"
        case "review":
            return "Review"
        case "command":
            return "Command"
        case "model":
            return "Model"
        case "experimentalFeature":
            return "Feature"
        case "collaborationMode":
            return "Mode"
        case "skills":
            return "Skills"
        case "app":
            return "Apps"
        case "mcpServer":
            return "MCP"
        case "tool":
            return "Tool"
        case "config", "configRequirements":
            return "Config"
        case "windowsSandbox":
            return "Sandbox"
        case "feedback":
            return "Feedback"
        case "account":
            return "Auth"
        default:
            return "Other"
        }
    }

    private func timestampString(_ date: Date) -> String {
        Self.timestampFormatter.string(from: date)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
