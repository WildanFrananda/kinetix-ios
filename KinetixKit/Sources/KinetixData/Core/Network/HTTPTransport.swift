import Foundation

public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPTransportError>
}
