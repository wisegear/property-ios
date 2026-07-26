import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case validation(String)
    case propertyNotFound
    case epcCertificateNotFound
    case schoolNotFound
    case schoolPostcodeNotFound
    case crimeAreaNotFound
    case rateLimited
    case serverUnavailable
    case offline
    case network
    case invalidResponse
    case invalidData

    var message: String {
        switch self {
        case .invalidURL:
            return "The request could not be created."
        case .validation(let message):
            return message
        case .propertyNotFound:
            return "Property not found."
        case .epcCertificateNotFound:
            return "EPC certificate not found."
        case .schoolNotFound:
            return "School not found."
        case .schoolPostcodeNotFound:
            return "That postcode could not be found."
        case .crimeAreaNotFound:
            return "Crime information for this area was not found."
        case .rateLimited:
            return "Too many requests. Please try again shortly."
        case .serverUnavailable:
            return "Property Research is temporarily unavailable. Please try again."
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        case .network:
            return "The property service could not be reached. Please try again."
        case .invalidResponse, .invalidData:
            return "Property data could not be loaded right now."
        }
    }

    var canRetry: Bool {
        switch self {
        case .offline, .network, .serverUnavailable:
            return true
        default:
            return false
        }
    }
}

struct LaravelValidationResponse: Decodable {
    let message: String?
    let errors: [String: [String]]?
}
