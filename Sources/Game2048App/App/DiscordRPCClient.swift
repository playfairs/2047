#if os(macOS)
    import Combine
    import Darwin
    import Foundation
    import OSLog

    struct DiscordActivity: Equatable {
        let isPlaying: Bool
        let score: Int
        let bestScore: Int
        let startedAt: Int?

        var details: String {
            isPlaying ? "Playing" : "In Menus"
        }

        var state: String? {
            isPlaying ? "Score: \(score.formatted()) · High Score: \(bestScore.formatted())" : nil
        }
    }

    @MainActor
    final class DiscordRPCManager: ObservableObject {
        @Published private(set) var statusMessage = "Off"

        private lazy var client = DiscordRPCClient { [weak self] message in
            Task { @MainActor [weak self] in
                self?.statusMessage = message
            }
        }
        private var isEnabled = false
        private var currentActivity: DiscordActivity?

        func update(
            enabled: Bool,
            isPlaying: Bool,
            score: Int,
            bestScore: Int,
            gameStartedAt: Date
        ) {
            guard enabled else {
                guard isEnabled else {
                    statusMessage = "Off"
                    return
                }
                isEnabled = false
                currentActivity = nil
                statusMessage = "Off"
                client.stop()
                return
            }

            isEnabled = true
            if currentActivity == nil {
                statusMessage = "Connecting to Discord…"
            }
            let activity = DiscordActivity(
                isPlaying: isPlaying,
                score: score,
                bestScore: bestScore,
                startedAt: isPlaying ? Int(gameStartedAt.timeIntervalSince1970) : nil
            )
            guard activity != currentActivity else { return }
            currentActivity = activity
            client.setActivity(activity)
        }

        func stop() {
            guard isEnabled else { return }
            isEnabled = false
            currentActivity = nil
            statusMessage = "Off"
            client.stop()
        }
    }

    private final class DiscordRPCClient: @unchecked Sendable {
        private static let applicationID = "1573083608854565034"
        private static let minimumActivityUpdateInterval: TimeInterval = 5
        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "2048",
            category: "discord-rpc"
        )

        private let statusHandler: @Sendable (String) -> Void
        private let queue = DispatchQueue(label: "dev.playfairs.2048.discord-rpc")
        private var socket: Int32 = -1
        private var readSource: DispatchSourceRead?
        private var retryTimer: DispatchSourceTimer?
        private var handshakeTimer: DispatchSourceTimer?
        private var activityUpdateTimer: DispatchSourceTimer?
        private var inputBuffer = Data()
        private var isRunning = false
        private var isReady = false
        private var didLogUnavailable = false
        private var didLogActivityAccepted = false
        private var lastActivitySentAt: Date?
        private var activity: DiscordActivity?

        init(statusHandler: @escaping @Sendable (String) -> Void) {
            self.statusHandler = statusHandler
        }

        func setActivity(_ activity: DiscordActivity) {
            queue.async {
                self.activity = activity
                guard !self.isRunning else {
                    if self.isReady {
                        self.scheduleActivityUpdate()
                    }
                    return
                }

                self.isRunning = true
                self.publishStatus("Connecting to Discord…")
                self.scheduleConnectionRetries()
                self.connectIfNeeded()
            }
        }

        func stop() {
            queue.async {
                guard self.isRunning else { return }
                if self.isReady {
                    self.sendCommand(
                        "SET_ACTIVITY",
                        arguments: ["pid": getpid(), "activity": NSNull()]
                    )
                    self.sendFrame(opcode: 2, payload: Data())
                }
                self.isRunning = false
                self.activity = nil
                self.publishStatus("Off")
                self.cancelTimers()
                self.closeConnection()
            }
        }

        private func scheduleConnectionRetries() {
            guard retryTimer == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 5, repeating: 5)
            timer.setEventHandler { [weak self] in
                self?.connectIfNeeded()
            }
            timer.resume()
            retryTimer = timer
        }

        private func connectIfNeeded() {
            guard isRunning, socket < 0 else { return }
            for path in candidateSocketPaths() {
                guard let connectedSocket = connect(to: path) else { continue }
                socket = connectedSocket
                isReady = false
                inputBuffer.removeAll(keepingCapacity: true)
                didLogUnavailable = false
                didLogActivityAccepted = false
                startReading()
                guard sendJSON(
                    opcode: 0,
                    object: ["v": 1, "client_id": Self.applicationID]
                ) else {
                    closeConnection()
                    continue
                }
                startHandshakeTimeout()
                return
            }

            if !didLogUnavailable {
                Self.logger.error("Could not connect to the Discord desktop IPC socket")
                didLogUnavailable = true
                publishStatus("Discord desktop app not detected")
            }
        }

        private func candidateSocketPaths() -> [String] {
            let environment = ProcessInfo.processInfo.environment
            let directories = ["XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP"]
                .compactMap { environment[$0] }
                + [NSTemporaryDirectory(), Self.darwinUserTemporaryDirectory, "/tmp"]
            var seen = Set<String>()
            return directories
                .flatMap { directory in
                    (0...9).map { "\(directory)/discord-ipc-\($0)" }
                }
                .filter { seen.insert($0).inserted }
        }

        private static var darwinUserTemporaryDirectory: String {
            let length = confstr(_CS_DARWIN_USER_TEMP_DIR, nil, 0)
            guard length > 1 else { return "/tmp" }
            var buffer = [CChar](repeating: 0, count: Int(length))
            guard confstr(_CS_DARWIN_USER_TEMP_DIR, &buffer, length) > 0 else {
                return "/tmp"
            }
            return String(cString: buffer)
        }

        private func connect(to path: String) -> Int32? {
            let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
            guard descriptor >= 0 else { return nil }
            var noSignal: Int32 = 1
            _ = setsockopt(
                descriptor,
                SOL_SOCKET,
                SO_NOSIGPIPE,
                &noSignal,
                socklen_t(MemoryLayout<Int32>.size)
            )

            var address = sockaddr_un()
            address.sun_family = sa_family_t(AF_UNIX)
            let pathCapacity = MemoryLayout.size(ofValue: address.sun_path)
            guard path.utf8.count + 1 <= pathCapacity else {
                Darwin.close(descriptor)
                return nil
            }
            path.withCString { source in
                withUnsafeMutablePointer(to: &address.sun_path) { pathPointer in
                    pathPointer.withMemoryRebound(to: CChar.self, capacity: pathCapacity) {
                        _ = strlcpy($0, source, pathCapacity)
                    }
                }
            }
            address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
            let result = withUnsafePointer(to: &address) { addressPointer in
                addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(
                        descriptor,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_un>.size)
                    )
                }
            }
            guard result == 0 else {
                Darwin.close(descriptor)
                return nil
            }

            let flags = fcntl(descriptor, F_GETFL)
            guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) == 0 else {
                Darwin.close(descriptor)
                return nil
            }
            return descriptor
        }

        private func startReading() {
            let source = DispatchSource.makeReadSource(fileDescriptor: socket, queue: queue)
            source.setEventHandler { [weak self] in
                self?.readAvailable()
            }
            source.resume()
            readSource = source
        }

        private func readAvailable() {
            guard socket >= 0 else { return }
            var bytes = [UInt8](repeating: 0, count: 8192)
            while true {
                let count = bytes.withUnsafeMutableBytes {
                    Darwin.read(socket, $0.baseAddress, $0.count)
                }
                if count > 0 {
                    inputBuffer.append(contentsOf: bytes.prefix(count))
                    guard processAvailableFrames() else { return }
                } else if count == 0 {
                    connectionEnded()
                    return
                } else if errno == EAGAIN || errno == EWOULDBLOCK {
                    return
                } else if errno != EINTR {
                    connectionEnded()
                    return
                }
            }
        }

        private func processAvailableFrames() -> Bool {
            while inputBuffer.count >= 8 {
                let opcode = readUInt32(at: 0)
                let payloadLength = Int(readUInt32(at: 4))
                guard payloadLength <= 1_048_576 else {
                    connectionEnded()
                    return false
                }
                guard inputBuffer.count >= payloadLength + 8 else { return true }
                let payload = inputBuffer.subdata(in: 8..<(payloadLength + 8))
                inputBuffer.removeSubrange(0..<(payloadLength + 8))

                switch opcode {
                case 1:
                    handleFrame(payload)
                case 2:
                    connectionEnded()
                    return false
                case 3:
                    sendFrame(opcode: 4, payload: payload)
                case 4:
                    break
                default:
                    continue
                }
            }
            return true
        }

        private func handleFrame(_ payload: Data) {
            guard
                let frame = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
            else {
                return
            }
            if frame["evt"] as? String == "READY" {
                isReady = true
                handshakeTimer?.cancel()
                handshakeTimer = nil
                publishStatus("Connected to Discord")
                retryTimer?.cancel()
                retryTimer = nil
                if let activity {
                    sendActivity(activity)
                }
            } else if frame["evt"] as? String == "ERROR" {
                let data = frame["data"] as? [String: Any]
                let message = data?["message"] as? String ?? "unknown error"
                Self.logger.error(
                    "Discord RPC error: \(message, privacy: .public)"
                )
                publishStatus("Discord error: \(message)")
            } else if frame["cmd"] as? String == "SET_ACTIVITY" {
                publishStatus("Rich Presence is active")
                if !didLogActivityAccepted {
                    Self.logger.info("Discord accepted Rich Presence activity")
                    didLogActivityAccepted = true
                }
            }
        }

        private func startHandshakeTimeout() {
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 5)
            timer.setEventHandler { [weak self] in
                guard let self, self.socket >= 0, !self.isReady else { return }
                Self.logger.error("Discord IPC handshake timed out")
                self.connectionEnded(status: "Discord did not respond; retrying")
            }
            timer.resume()
            handshakeTimer = timer
        }

        private func sendActivity(_ activity: DiscordActivity) {
            var details: [String: Any] = [
                "details": activity.details,
                "type": 0
            ]
            if let startedAt = activity.startedAt {
                details["timestamps"] = ["start": startedAt]
            }
            if let state = activity.state {
                details["state"] = state
            }
            if sendCommand(
                "SET_ACTIVITY",
                arguments: ["pid": getpid(), "activity": details]
            ) {
                lastActivitySentAt = Date()
            }
        }

        private func scheduleActivityUpdate() {
            guard isReady, let activity else { return }
            guard let lastActivitySentAt else {
                sendActivity(activity)
                return
            }
            let delay =
                Self.minimumActivityUpdateInterval - Date().timeIntervalSince(lastActivitySentAt)
            guard delay > 0 else {
                cancelActivityUpdate()
                sendActivity(activity)
                return
            }
            guard activityUpdateTimer == nil else { return }

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + delay)
            timer.setEventHandler { [weak self] in
                guard let self else { return }
                self.cancelActivityUpdate()
                guard self.isReady, let activity = self.activity else { return }
                self.sendActivity(activity)
            }
            timer.resume()
            activityUpdateTimer = timer
        }

        @discardableResult
        private func sendCommand(_ command: String, arguments: [String: Any]) -> Bool {
            sendJSON(
                opcode: 1,
                object: [
                    "cmd": command,
                    "args": arguments,
                    "nonce": UUID().uuidString
                ]
            )
        }

        @discardableResult
        private func sendJSON(opcode: UInt32, object: [String: Any]) -> Bool {
            guard let payload = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.sortedKeys]
            ) else {
                Self.logger.error("Could not encode a Discord RPC payload")
                return false
            }
            return sendFrame(opcode: opcode, payload: payload)
        }

        @discardableResult
        private func sendFrame(opcode: UInt32, payload: Data) -> Bool {
            guard socket >= 0 else { return false }
            var frame = Data()
            appendLittleEndian(opcode, to: &frame)
            appendLittleEndian(UInt32(payload.count), to: &frame)
            frame.append(payload)

            let succeeded = frame.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else { return false }
                var offset = 0
                while offset < bytes.count {
                    let written = Darwin.write(
                        socket,
                        baseAddress.advanced(by: offset),
                        bytes.count - offset
                    )
                    if written > 0 {
                        offset += written
                    } else if written < 0, errno == EINTR {
                        continue
                    } else if written < 0, errno == EAGAIN || errno == EWOULDBLOCK {
                        var writable = pollfd(fd: socket, events: Int16(POLLOUT), revents: 0)
                        guard poll(&writable, 1, 1000) > 0 else { return false }
                    } else {
                        return false
                    }
                }
                return true
            }
            if !succeeded {
                connectionEnded()
            }
            return succeeded
        }

        private func appendLittleEndian(_ value: UInt32, to data: inout Data) {
            data.append(UInt8(value & 0xFF))
            data.append(UInt8((value >> 8) & 0xFF))
            data.append(UInt8((value >> 16) & 0xFF))
            data.append(UInt8((value >> 24) & 0xFF))
        }

        private func readUInt32(at offset: Int) -> UInt32 {
            UInt32(inputBuffer[offset])
                | UInt32(inputBuffer[offset + 1]) << 8
                | UInt32(inputBuffer[offset + 2]) << 16
                | UInt32(inputBuffer[offset + 3]) << 24
        }

        private func connectionEnded(status: String = "Reconnecting to Discord…") {
            closeConnection()
            if isRunning {
                publishStatus(status)
                scheduleConnectionRetries()
            } else {
                publishStatus("Off")
            }
        }

        private func publishStatus(_ message: String) {
            statusHandler(message)
        }

        private func closeConnection() {
            handshakeTimer?.cancel()
            handshakeTimer = nil
            cancelActivityUpdate()
            if let readSource {
                readSource.setEventHandler {}
                readSource.cancel()
                self.readSource = nil
            }
            if socket >= 0 {
                Darwin.close(socket)
                socket = -1
            }
            isReady = false
            inputBuffer.removeAll(keepingCapacity: false)
        }

        private func cancelTimers() {
            retryTimer?.cancel()
            retryTimer = nil
            cancelActivityUpdate()
        }

        private func cancelActivityUpdate() {
            activityUpdateTimer?.cancel()
            activityUpdateTimer = nil
        }
    }
#endif
