import SwiftUI
import CodexAppServerSDK

@MainActor
@Observable
final class SDKSampleIntegrationModel {
    var serverURL: String = AppModel.defaultWebSocketURL
    var connectionStatusText: String = "Disconnected"
    var isConnected = false
    var isBusy = false

    var modelIDs: [String] = []
    var requestJSON = ""
    var responseJSON = ""
    var events: [String] = []

    private let client = CodexAppServerClient()
    private var inboundTask: Task<Void, Never>?

    func connectAndInitialize() async {
        guard isBusy == false else { return }

        guard let url = URL(string: serverURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss" else {
            connectionStatusText = "Failed: invalid websocket URL"
            responseJSON = EndpointJSONFormatter.genericErrorJSON("Invalid websocket URL: \(serverURL)")
            return
        }

        isBusy = true
        connectionStatusText = "Connecting..."

        let params = InitializeParams(
            clientInfo: ClientInfo(
                name: "swiftcodex_sample",
                title: "SwiftCodex Sample Integration",
                version: "1.0.0"
            ),
            capabilities: ClientCapabilities(experimentalApi: true)
        )

        do {
            let paramsJSON = try JSONValueCoding.encode(params)
            requestJSON = EndpointJSONFormatter.requestJSON(
                method: AppServerMethod.initialize.rawValue,
                params: paramsJSON
            )

            try await client.connectWebSocket(url: url)
            startInboundLogging()

            let result = try await client.initialize(params)
            try client.initialized()

            let resultJSON = try JSONValueCoding.encode(result)
            responseJSON = EndpointJSONFormatter.responseJSON(
                result: resultJSON,
                initializationAcknowledged: true
            )

            isConnected = true
            connectionStatusText = "Connected"
            appendEvent("initialized")
        } catch {
            isConnected = false
            connectionStatusText = "Failed"
            responseJSON = EndpointJSONFormatter.genericErrorJSON(error.localizedDescription)
            appendEvent("error: \(error.localizedDescription)")
        }

        isBusy = false
    }

    func listModels() async {
        guard isBusy == false else { return }
        guard isConnected else {
            responseJSON = EndpointJSONFormatter.genericErrorJSON("Not connected")
            return
        }

        isBusy = true

        do {
            let params = ModelListParams(includeHidden: true)
            let paramsJSON = try JSONValueCoding.encode(params)
            requestJSON = EndpointJSONFormatter.requestJSON(
                method: AppServerMethod.modelList.rawValue,
                params: paramsJSON
            )

            let result = try await client.modelList(params)
            modelIDs = result.data.compactMap(\.id).sorted()

            let resultJSON = try JSONValueCoding.encode(result)
            responseJSON = EndpointJSONFormatter.responseJSON(result: resultJSON)
            appendEvent("model/list completed")
        } catch {
            responseJSON = EndpointJSONFormatter.genericErrorJSON(error.localizedDescription)
            appendEvent("error: \(error.localizedDescription)")
        }

        isBusy = false
    }

    func disconnect() {
        inboundTask?.cancel()
        inboundTask = nil

        client.disconnect()

        isConnected = false
        isBusy = false
        connectionStatusText = "Disconnected"
        appendEvent("disconnected")
    }

    private func startInboundLogging() {
        inboundTask?.cancel()

        inboundTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for await message in client.inboundMessages {
                switch message {
                case .notification(let notification):
                    appendEvent("notification: \(notification.method.rawValue)")
                case .request(let request):
                    appendEvent("request: \(request.method.rawValue)")
                case .stderr(let line):
                    appendEvent("stderr: \(line)")
                case .disconnected(let exitCode):
                    isConnected = false
                    connectionStatusText = "Disconnected"
                    appendEvent("connection closed: \(exitCode.map(String.init) ?? "n/a")")
                }
            }
        }
    }

    private func appendEvent(_ event: String) {
        events.append(event)
        if events.count > 120 {
            events.removeFirst(events.count - 120)
        }
    }
}

struct SDKSampleIntegrationView: View {
    @State private var model = SDKSampleIntegrationModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            controls
            modelList
            jsonPanels
            eventLog
        }
        .padding(20)
        .frame(minWidth: 980, minHeight: 760, alignment: .topLeading)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SDK WebSocket Sample")
                .font(.title2.weight(.semibold))
            Text("Preview-only test view for connect + initialize + model/list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            TextField("ws://host-or-ip:4500", text: $model.serverURL)
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, design: .monospaced))

            Button("Connect + Initialize") {
                Task { await model.connectAndInitialize() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy || model.isConnected)

            Button("List Models") {
                Task { await model.listModels() }
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy || !model.isConnected)

            Button("Disconnect") {
                model.disconnect()
            }
            .buttonStyle(.bordered)
            .disabled(!model.isConnected)

            Spacer()

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.isConnected ? .green : .gray)
                .frame(width: 8, height: 8)
            Text(model.connectionStatusText)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }

    private var modelList: some View {
        GroupBox("Models") {
            if model.modelIDs.isEmpty {
                Text("No models loaded yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(model.modelIDs, id: \.self) { modelID in
                            Text(modelID)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            }
        }
    }

    private var jsonPanels: some View {
        HStack(alignment: .top, spacing: 12) {
            GroupBox("Request") {
                ScrollView {
                    Text(model.requestJSON.isEmpty ? "No request yet." : model.requestJSON)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 180, maxHeight: 240)
            }

            GroupBox("Response") {
                ScrollView {
                    Text(model.responseJSON.isEmpty ? "No response yet." : model.responseJSON)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 180, maxHeight: 240)
            }
        }
    }

    private var eventLog: some View {
        GroupBox("Inbound Events") {
            ScrollView {
                if model.events.isEmpty {
                    Text("No events yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(model.events.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minHeight: 160)
        }
    }
}

#Preview("SDK Sample") {
    SDKSampleIntegrationView()
}
