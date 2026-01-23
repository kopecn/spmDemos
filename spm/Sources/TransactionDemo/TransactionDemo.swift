import ArgumentParser
import Foundation
import SwiftRobotics
import NIOHandler
import FoundationInterfaces
import OpenCombine

@main
struct TransactionDemo: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A demo for TransactionHandler with NIOSocketHandlerServer via MessageDuplex.",
        subcommands: [Server.self],
        defaultSubcommand: Server.self
    )
}

extension TransactionDemo {
    struct Server: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Start the socket server and manage transactions."
        )

        @Option(name: .shortAndLong, help: "The port to listen on.")
        var port: Int = 9000

        @Flag(name: .shortAndLong, help: "Enable verbose output.")
        var verbose: Bool = false

        func run() throws {
            print("TransactionDemo Server")
            print("======================")
            print("Starting server on port \(port)...")

            let socketServer = NIOSocketHandlerServer(name: "transaction-demo-server")
            let transactionHandler = TransactionHandler<RobotCommand>(resourceID: "demo-device")

            transactionHandler.attachPipe(socketServer)

            transactionHandler.messageParser = { handler, message in
                print("\n[INBOUND] \(message)")
                print("> ", terminator: "")
                fflush(stdout)

                parseAndProcessMessage(handler: handler, message: message)
            }

            var deviceStateCancellable: AnyCancellable?
            deviceStateCancellable = transactionHandler.deviceStatePublisher.sink { state in
                if verbose {
                    print("\n[STATE] Device state changed to: \(state)")
                    print("> ", terminator: "")
                    fflush(stdout)
                }
            }

            var connectionCancellable: AnyCancellable?
            connectionCancellable = socketServer.serverConnectionStatePublisher.sink { state in
                print("\n[SERVER] Connection state: \(state)")
                print("> ", terminator: "")
                fflush(stdout)
            }

            var clientsCancellable: AnyCancellable?
            clientsCancellable = socketServer.connectedClientIDsPublisher.sink { clients in
                if !clients.isEmpty {
                    print("\n[SERVER] Connected clients: \(clients.count)")
                    print("> ", terminator: "")
                    fflush(stdout)
                }
            }

            socketServer.listen(port: port)

            print("Server listening on port \(port)")
            print("Type messages and press Enter to send. Type 'quit' to exit.")
            print("Commands: 'status', 'state', 'quit'")
            print("")

            runInputLoop(socketServer: socketServer, transactionHandler: transactionHandler, verbose: verbose)

            socketServer.shutdown()

            _ = deviceStateCancellable
            _ = connectionCancellable
            _ = clientsCancellable

            print("Server shut down.")
        }
    }
}

private func runInputLoop(
    socketServer: NIOSocketHandlerServer,
    transactionHandler: TransactionHandler<RobotCommand>,
    verbose: Bool
) {
    print("> ", terminator: "")
    fflush(stdout)

    while let line = readLine() {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            print("> ", terminator: "")
            fflush(stdout)
            continue
        }

        switch trimmed.lowercased() {
        case "quit", "exit", "q":
            print("Shutting down...")
            return

        case "status":
            let stats = socketServer.getConnectionStats()
            print("[STATUS] Connection stats: \(stats)")

        case "state":
            print("[STATE] Device state: \(transactionHandler.deviceState)")
            print("[STATE] Has pipe: \(transactionHandler.hasPipe)")
            print("[STATE] Motion queue: \(transactionHandler.motionQueueCount)")
            print("[STATE] Active queries: \(transactionHandler.activeQueryCount)")

        case "help":
            print("Commands:")
            print("  status  - Show connection statistics")
            print("  state   - Show transaction handler state")
            print("  quit    - Exit the demo")
            print("  <text>  - Send text message to connected clients")

        default:
            let success = socketServer.send(trimmed)
            if verbose {
                print("[SENT] '\(trimmed)' - success: \(success)")
            }
        }

        print("> ", terminator: "")
        fflush(stdout)
    }
}

private func parseAndProcessMessage(
    handler: TransactionHandler<RobotCommand>,
    message: String
) {
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if trimmed.hasPrefix("<") && trimmed.hasSuffix(">") {
        let content = String(trimmed.dropFirst().dropLast())
        let parts = content.split(separator: ",").map { String($0) }

        guard parts.count >= 2 else { return }

        if let transactionID = Int(parts[0]) {
            let responseType = parts[1].lowercased()

            switch responseType {
            case "ack":
                handler.processAcknowledgment(transactionID: transactionID)

            case "ok", "done", "complete":
                let response = parts.count > 2 ? parts[2...].joined(separator: ",") : nil
                handler.processResponse(transactionID: transactionID, response: response)

            case "err", "error":
                let errorMsg = parts.count > 2 ? parts[2...].joined(separator: ",") : "Unknown error"
                handler.processError(transactionID: transactionID, message: errorMsg)

            case "event":
                if parts.count > 2, let eventCode = Int(parts[2]) {
                    let payload = parts.count > 3 ? parts[3...].joined(separator: ",") : nil
                    handler.processEvent(code: eventCode, payload: payload, transactionID: transactionID)
                }

            default:
                break
            }
        }
    }
}
