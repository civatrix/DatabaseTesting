//
//  TripModels.swift
//  WestJet
//
//  Created by David Anderson on 2018-09-19.
//  Copyright © 2018 WestJet Airlines Ltd. All rights reserved.
//

import Foundation
import GRDB

// MARK: Models

/// Metadata that is not part of the trip fetched from the API, but that is directly associated with the trip
/// This data can be directly or indirectly modified by the user through use of the app, while the raw trip itself must be modified via RBF/Sabre
public struct TripMetadata: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let isSoftDeleted: Bool
    public let isCachedDataStale: Bool // used when a PNR in a push payload is used to load a trip
    public let isPrematurelyComplete: Bool
    // the following are optional
    public let refreshDate: Date?
    public let tripName: String? // added by user
    public let bookingLastName: String? // name comes from original add-trip request
    public let bookingAccountIDHash: String? // hash occurs when added as part of a profile
    
    init() {
        self.tripName = nil
        self.bookingLastName = nil
        self.bookingAccountIDHash = nil
        self.refreshDate = nil
        self.isSoftDeleted = false
        self.isCachedDataStale = false
        self.isPrematurelyComplete = false
    }
    
    public init(isSoftDeleted: Bool,
                isCachedDataStale: Bool,
                isPrematurelyComplete: Bool,
                refreshDate: Date? = nil,
                tripName: String? = nil,
                bookingLastName: String? = nil,
                bookingAccountIDHash: String? = nil
        ) {
        self.refreshDate = refreshDate
        self.isSoftDeleted = isSoftDeleted
        self.isCachedDataStale = isCachedDataStale
        self.isPrematurelyComplete = isPrematurelyComplete
        self.tripName = tripName
        self.bookingLastName = bookingLastName
        self.bookingAccountIDHash = bookingAccountIDHash
    }
}

public struct Trip: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let passengerNameRecord: String
    public let pseudoCityCode: String
    public let guests: [Guest]
    public let originDestinations: [OriginDestination]
    public let unconfirmedLegs: [UnconfirmedLeg]
    public let bookingNumber: String? // booking number is present when this is a WVI trip
    public let fullyUnconfirmed: Bool
    public let priority: StandbyPriority?
    public let eligibility: ManageTripEligibility?
    public let metadata: TripMetadata
    
    private enum CodingKeys: String, CodingKey {
        case passengerNameRecord = "pnr"
        case pseudoCityCode = "aaaPseudoCityCode"
        case guests
        case originDestinations
        case unconfirmedLegs
        case bookingNumber
        case fullyUnconfirmed
        case priority = "priorityCode"
        case eligibility
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            passengerNameRecord = try values.decode(String.self, forKey: .passengerNameRecord)
            pseudoCityCode = try values.decode(String.self, forKey: .pseudoCityCode)
            guests = try values.decodeIfPresent([Guest].self, forKey: .guests) ?? []
            
            originDestinations = try values.decodeIfPresent([OriginDestination].self, forKey: .originDestinations) ?? []
            unconfirmedLegs = try values.decodeIfPresent([UnconfirmedLeg].self, forKey: .unconfirmedLegs) ?? []
            bookingNumber = try values.decodeIfPresent(String.self, forKey: .bookingNumber) // booking number is present when this is a WVI trip
            fullyUnconfirmed = try values.decodeIfPresent(Bool.self, forKey: .fullyUnconfirmed) ?? false
            priority = try values.decodeIfPresent(StandbyPriority.self, forKey: .priority)
            eligibility = try values.decodeIfPresent(ManageTripEligibility.self, forKey: .eligibility)
            metadata = try values.decodeIfPresent(TripMetadata.self, forKey: .metadata) ?? TripMetadata()
        } catch {
            NSLog("Failed to decode Trip: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(passengerNameRecord, forKey: .passengerNameRecord)
        try container.encode(pseudoCityCode, forKey: .pseudoCityCode)
        try container.encode(guests, forKey: .guests)
        try container.encode(originDestinations, forKey: .originDestinations)
        try container.encode(unconfirmedLegs, forKey: .unconfirmedLegs)
        try container.encode(bookingNumber, forKey: .bookingNumber)
        try container.encode(fullyUnconfirmed, forKey: .fullyUnconfirmed)
        try container.encode(priority, forKey: .priority)
        try container.encode(eligibility, forKey: .eligibility)
        try container.encode(metadata, forKey: .metadata)
    }
    
    public init(
        passengerNameRecord: String,
        pseudoCityCode: String,
        guests: [Guest],
        originDestinations: [OriginDestination],
        unconfirmedLegs: [UnconfirmedLeg],
        bookingNumber: String? = nil,
        fullyUnconfirmed: Bool,
        priority: StandbyPriority? = nil,
        eligibility: ManageTripEligibility?,
        metadata: TripMetadata
        ) {
        self.passengerNameRecord = passengerNameRecord
        self.pseudoCityCode = pseudoCityCode
        self.guests = guests
        self.originDestinations = originDestinations
        self.unconfirmedLegs = unconfirmedLegs
        self.bookingNumber = bookingNumber
        self.fullyUnconfirmed = fullyUnconfirmed
        self.priority = priority
        self.eligibility = eligibility
        self.metadata = metadata
    }
}

public struct OriginDestination: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let arrivalDateTime: Date
    public let departureDateTime: Date
    public let destinationAirportCode: String
    public let durationMinutes: Int
    public let originAirportCode: String
    public let segments: [Segment]
    
    public struct Metadata: Codable, FetchableRecord, MutablePersistableRecord {
        public let hasHandledCheckInNotification: Bool
        
        public init(hasHandledCheckInNotification: Bool) {
            self.hasHandledCheckInNotification = hasHandledCheckInNotification
        }
    }
    public let metadata: Metadata
    
    public init(
        arrivalDateTime: Date,
        departureDateTime: Date,
        destinationAirportCode: String,
        durationMinutes: Int,
        originAirportCode: String,
        segments: [Segment],
        metadata: Metadata
        ) {
        self.arrivalDateTime = arrivalDateTime
        self.departureDateTime = departureDateTime
        self.destinationAirportCode = destinationAirportCode
        self.durationMinutes = durationMinutes
        self.originAirportCode = originAirportCode
        self.segments = segments
        self.metadata = metadata
    }
    
    enum CodingKeys: String, CodingKey {
        case arrivalDateTime
        case departureDateTime
        case destinationAirportCode
        case durationMinutes
        case originAirportCode
        case segments
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            arrivalDateTime = try container.decode(Date.self, forKey: .arrivalDateTime)
            departureDateTime = try container.decode(Date.self, forKey: .departureDateTime)
            destinationAirportCode = try container.decode(String.self, forKey: .destinationAirportCode)
            durationMinutes = try container.decode(IntAsPossibleStringJSONWrapper.self, forKey: .durationMinutes).int // MIMHKX.json has durationMinutes as strings.
            originAirportCode = try container.decode(String.self, forKey: .originAirportCode)
            segments = try container.decode([Segment].self, forKey: .segments)
            
            // When decoding from API JSON we won't have metadata and use appropriate defaults
            // When decoding from local storage we want to use our saved metadata
            metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata) ?? Metadata(hasHandledCheckInNotification: false)
        } catch {
            NSLog("Failed to decode OriginDestination: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(arrivalDateTime, forKey: .arrivalDateTime)
        try container.encode(departureDateTime, forKey: .departureDateTime)
        try container.encode(destinationAirportCode, forKey: .destinationAirportCode)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(originAirportCode, forKey: .originAirportCode)
        try container.encode(segments, forKey: .segments)
        try container.encode(metadata, forKey: .metadata)
    }
}

public struct Segment: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let type: LegType
    public let durationMinutes: Int
    public let itineraryAirlineType: String? // not set for layovers
    public let marketingAirlineCode: String? // not set for layovers
    public var operatingAirlineName: String? // sometimes not set
    public let departureDateTime: Date? // not set for layovers
    public let destinationAirportCode: String? // not set for layovers
    public let originAirportCode: String? // not set for layover
    public let flightNumber: String? // not set for layover
    public let arrivalDateTime: Date? // not set for layovers
    public var legs: [Leg]? // not set for layovers
    
    private enum CodingKeys: String, CodingKey {
        case type
        case durationMinutes
        case itineraryAirlineType
        case marketingAirlineCode
        case operatingAirlineName
        case departureDateTime
        case destinationAirportCode
        case originAirportCode
        case flightNumber
        case arrivalDateTime
        case legs
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            type = try values.decode(LegType.self, forKey: .type)
            durationMinutes = try values.decode(IntAsPossibleStringJSONWrapper.self, forKey: .durationMinutes).int // MIMHKX.json has durationMinutes as strings.
            itineraryAirlineType = try values.decodeIfPresent(String.self, forKey: .itineraryAirlineType)
            marketingAirlineCode = try values.decodeIfPresent(String.self, forKey: .marketingAirlineCode)
            operatingAirlineName = try values.decodeIfPresent(String.self, forKey: .operatingAirlineName)
            departureDateTime = try values.decodeIfPresent(Date.self, forKey: .departureDateTime)
            destinationAirportCode = try values.decodeIfPresent(String.self, forKey: .destinationAirportCode)
            originAirportCode = try values.decodeIfPresent(String.self, forKey: .originAirportCode)
            flightNumber = try values.decodeIfPresent(String.self, forKey: .flightNumber)
            arrivalDateTime = try values.decodeIfPresent(Date.self, forKey: .arrivalDateTime)
            legs = try values.decodeIfPresent([Leg].self, forKey: .legs)
        } catch {
            NSLog("Failed to decode Segment: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(itineraryAirlineType, forKey: .itineraryAirlineType)
        try container.encode(marketingAirlineCode, forKey: .marketingAirlineCode)
        try container.encode(operatingAirlineName, forKey: .operatingAirlineName)
        try container.encode(departureDateTime, forKey: .departureDateTime)
        try container.encode(destinationAirportCode, forKey: .destinationAirportCode)
        try container.encode(originAirportCode, forKey: .originAirportCode)
        try container.encode(flightNumber, forKey: .flightNumber)
        try container.encode(arrivalDateTime, forKey: .arrivalDateTime)
        try container.encode(legs, forKey: .legs)
    }
    
    public init(
        type: LegType,
        durationMinutes: Int,
        itineraryAirlineType: String? = nil,
        marketingAirlineCode: String? = nil,
        operatingAirlineName: String? = nil,
        departureDateTime: Date? = nil,
        destinationAirportCode: String? = nil,
        originAirportCode: String? = nil,
        flightNumber: String? = nil,
        arrivalDateTime: Date? = nil,
        legs: [Leg]? = nil
        ) {
        self.type = type
        self.durationMinutes = durationMinutes
        self.itineraryAirlineType = itineraryAirlineType
        self.marketingAirlineCode = marketingAirlineCode
        self.operatingAirlineName = operatingAirlineName
        self.departureDateTime = departureDateTime
        self.destinationAirportCode = destinationAirportCode
        self.originAirportCode = originAirportCode
        self.flightNumber = flightNumber
        self.arrivalDateTime = arrivalDateTime
        self.legs = legs
    }
}

public enum LegType: String, Codable, FetchableRecord, MutablePersistableRecord {
    case flight
    case layover
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            let typeString = try container.decode(String.self)
            guard let legType = LegType(rawValue: typeString.lowercased()) else {
                throw DecodingError.typeMismatch(LegType.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected string to represent a LegType"))
            }
            self = legType
        } catch {
            NSLog("Failed to decode LegType: \(error)")
            throw error
        }
    }
}

public struct Leg: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let type: LegType
    public let durationMinutes: Int
    public let itineraryAirlineType: String? // sometimes not set
    public let marketingAirlineCode: String? // not set for layover
    public var operatingAirlineName: String? // sometimes not set
    public let departureDateTime: Date? // not set for layover
    public let arrivalDateTime: Date? // not set for layover
    public let cabin: Cabin?
    public let destinationAirportCode: String? // not set for layover
    public let originAirportCode: String? // not set for layover
    public let status: String? // not set for layover
    public let flightNumber: String? // not set for layover
    public let standby: Standby?
    
    public struct Metadata: Codable, FetchableRecord, MutablePersistableRecord {
        public let latestFlightStatus: FlightStatusDetails?
        
        public init(latestFlightStatus: FlightStatusDetails?) {
            self.latestFlightStatus = latestFlightStatus
        }
    }
    public let metadata: Metadata
    
    private enum CodingKeys: String, CodingKey {
        case type
        case durationMinutes
        case itineraryAirlineType
        case marketingAirlineCode
        case operatingAirlineName
        case departureDateTime
        case arrivalDateTime
        case cabin
        case destinationAirportCode
        case originAirportCode
        case status // enum???
        case flightNumber
        case standby
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            type = try values.decode(LegType.self, forKey: .type)
            durationMinutes = try values.decode(IntAsPossibleStringJSONWrapper.self, forKey: .durationMinutes).int // MIMHKX.json has durationMinutes as strings.
            itineraryAirlineType = try values.decodeIfPresent(String.self, forKey: .itineraryAirlineType)
            marketingAirlineCode = try values.decodeIfPresent(String.self, forKey: .marketingAirlineCode)
            operatingAirlineName = try values.decodeIfPresent(String.self, forKey: .operatingAirlineName)
            departureDateTime = try values.decodeIfPresent(Date.self, forKey: .departureDateTime)
            arrivalDateTime = try values.decodeIfPresent(Date.self, forKey: .arrivalDateTime)
            cabin = try values.decodeIfPresent(Cabin.self, forKey: .cabin)
            destinationAirportCode = try values.decodeIfPresent(String.self, forKey: .destinationAirportCode)
            originAirportCode = try values.decodeIfPresent(String.self, forKey: .originAirportCode)
            status = try values.decodeIfPresent(String.self, forKey: .status) // enum?
            flightNumber = try values.decodeIfPresent(String.self, forKey: .flightNumber)
            standby = try values.decodeIfPresent(Standby.self, forKey: .standby)
            
            // When decoding from API JSON we won't have metadata and use appropriate defaults
            // When decoding from local storage we want to use our saved metadata
            metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata) ?? Metadata(latestFlightStatus: nil)
        } catch {
            NSLog("Failed to decode Leg: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(itineraryAirlineType, forKey: .itineraryAirlineType)
        try container.encode(marketingAirlineCode, forKey: .marketingAirlineCode)
        try container.encode(operatingAirlineName, forKey: .operatingAirlineName)
        try container.encode(departureDateTime, forKey: .departureDateTime)
        try container.encode(arrivalDateTime, forKey: .arrivalDateTime)
        try container.encode(cabin, forKey: .cabin)
        try container.encode(destinationAirportCode, forKey: .destinationAirportCode)
        try container.encode(originAirportCode, forKey: .originAirportCode)
        try container.encode(status, forKey: .status)
        try container.encode(flightNumber, forKey: .flightNumber)
        try container.encode(standby, forKey: .standby)
        try container.encode(metadata, forKey: .metadata)
    }
    
    public init(
        type: LegType,
        durationMinutes: Int,
        itineraryAirlineType: String? = nil,
        marketingAirlineCode: String? = nil,
        operatingAirlineName: String? = nil,
        departureDateTime: Date? = nil,
        arrivalDateTime: Date? = nil,
        cabin: Cabin? = nil,
        destinationAirportCode: String? = nil,
        originAirportCode: String? = nil,
        status: String? = nil,
        flightNumber: String? = nil,
        standby: Standby? = nil,
        metadata: Metadata
        ) {
        self.type = type
        self.durationMinutes = durationMinutes
        self.itineraryAirlineType = itineraryAirlineType
        self.marketingAirlineCode = marketingAirlineCode
        self.operatingAirlineName = operatingAirlineName
        self.departureDateTime = departureDateTime
        self.destinationAirportCode = destinationAirportCode
        self.originAirportCode = originAirportCode
        self.status = status
        self.flightNumber = flightNumber
        self.arrivalDateTime = arrivalDateTime
        self.standby = standby
        self.cabin = cabin
        self.metadata = metadata
    }
}

public struct UnconfirmedLeg: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    
    public let arrivalDateTime: Date
    public let departureDateTime: Date
    public let destinationAirportCode: String
    public let originAirportCode: String
    public let durationMinutes: Int
    public let flightNumber: String
    public let marketingAirlineCode: String
    public var operatingAirlineName: String?
    public let status: String // enum?
    public let type: LegType
    
    private enum CodingKeys: String, CodingKey {
        case arrivalDateTime
        case departureDateTime
        case destinationAirportCode
        case originAirportCode
        case durationMinutes
        case flightNumber
        case marketingAirlineCode
        case operatingAirlineName
        case status
        case type
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            arrivalDateTime = try values.decode(Date.self, forKey: .arrivalDateTime)
            departureDateTime = try values.decode(Date.self, forKey: .departureDateTime)
            destinationAirportCode = try values.decode(String.self, forKey: .destinationAirportCode)
            durationMinutes = try values.decode(IntAsPossibleStringJSONWrapper.self, forKey: .durationMinutes).int // MIMHKX.json has durationMinutes as strings.
            flightNumber = try values.decode(String.self, forKey: .flightNumber)
            marketingAirlineCode = try values.decode(String.self, forKey: .marketingAirlineCode)
            operatingAirlineName = try values.decodeIfPresent(String.self, forKey: .operatingAirlineName)
            originAirportCode = try values.decode(String.self, forKey: .originAirportCode)
            status = try values.decode(String.self, forKey: .status)
            type = try values.decode(LegType.self, forKey: .type)
        } catch {
            NSLog("Failed to decode UnconfirmedLeg: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(arrivalDateTime, forKey: .arrivalDateTime)
        try container.encode(departureDateTime, forKey: .departureDateTime)
        try container.encode(destinationAirportCode, forKey: .destinationAirportCode)
        try container.encode(originAirportCode, forKey: .originAirportCode)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(flightNumber, forKey: .flightNumber)
        try container.encode(marketingAirlineCode, forKey: .marketingAirlineCode)
        try container.encode(operatingAirlineName, forKey: .operatingAirlineName)
        try container.encode(status, forKey: .status)
        try container.encode(type, forKey: .type)
    }
    
    public init(
        arrivalDateTime: Date,
        departureDateTime: Date,
        destinationAirportCode: String,
        originAirportCode: String,
        durationMinutes: Int,
        flightNumber: String,
        marketingAirlineCode: String,
        operatingAirlineName: String?,
        status: String,
        type: LegType
        ) {
        self.arrivalDateTime = arrivalDateTime
        self.departureDateTime = departureDateTime
        self.destinationAirportCode = destinationAirportCode
        self.originAirportCode = originAirportCode
        self.durationMinutes = durationMinutes
        self.flightNumber = flightNumber
        self.marketingAirlineCode = marketingAirlineCode
        self.operatingAirlineName = operatingAirlineName
        self.status = status
        self.type = type
    }
}

public struct Cabin: Codable, FetchableRecord, MutablePersistableRecord {
    public let code: String
    public let language: String
    public let name: String
    public let sabreCode: String
    public let shortName: String
    
    public init(
        code: String,
        language: String,
        name: String,
        sabreCode: String,
        shortName: String
        ) {
        self.code = code
        self.language = language
        self.name = name
        self.sabreCode = sabreCode
        self.shortName = shortName
    }
    
}

public struct ManageTripEligibilityStatus: Codable, FetchableRecord, MutablePersistableRecord {
    public let eligible: Bool
    public let errorCode: String?
    
    public init(eligible: Bool, errorCode: String? = nil) {
        self.eligible = eligible
        self.errorCode = errorCode
    }
}

public struct ManageTripEligibility: Codable, FetchableRecord, MutablePersistableRecord {
    public let changeStatus: ManageTripEligibilityStatus
    public let cancelStatus: ManageTripEligibilityStatus
    public let seatsStatus: ManageTripEligibilityStatus
    public let guestsStatus: ManageTripEligibilityStatus
    
    private enum CodingKeys: String, CodingKey {
        case changeStatus = "CHG"
        case cancelStatus = "CXL"
        case seatsStatus = "Seat"
        case guestsStatus = "Info"
    }
    
    public init(
        changeStatus: ManageTripEligibilityStatus,
        cancelStatus: ManageTripEligibilityStatus,
        seatsStatus: ManageTripEligibilityStatus,
        guestsStatus: ManageTripEligibilityStatus
        ) {
        self.changeStatus = changeStatus
        self.cancelStatus = cancelStatus
        self.seatsStatus = seatsStatus
        self.guestsStatus = guestsStatus
    }
}

public struct Guest: Codable, FetchableRecord, MutablePersistableRecord {
    public let firstName: String
    public let lastName: String
    public let title: String // can be null, but we want a default value
    public var westjetIDHash: String?
    
    private enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case title
        case westjetIDHash = "westjetId"
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            firstName = try values.decode(String.self, forKey: .firstName)
            lastName = try values.decode(String.self, forKey: .lastName)
            
            title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
            
            if let westjetID = try values.decodeIfPresent(String.self, forKey: .westjetIDHash) {
                westjetIDHash = westjetID
            } else {
                westjetIDHash = nil
            }
        } catch {
            NSLog("Failed to decode Guest: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(title, forKey: .title)
        try container.encode(westjetIDHash, forKey: .westjetIDHash)
    }
    
    public init(firstName: String, lastName: String, title: String, westjetIDHash: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.title = title
        self.westjetIDHash = westjetIDHash
    }
}

// only public to be testable, but might not need to be
@objc
public enum StandbyPriorityType: Int {
    case deadHeadCrew = 0
    case deadHeadCrewThrough
    case soldOutGuest
    case soldOutGuestThrough
    case employeeOnBusiness
    case employeeOnBusinessThrough
    case partnerAirlineEmployeeOnBusiness
    case partnerAirlineEmployeeOnBusinessThrough
    case earlyShowGuest
    case earlyShowGuestThrough
    case employeeOrDesignate
    case employeeOrDesignateThrough
    case earlyOutOrRetiree
    case earlyOutOrRetireeThrough
    case parent
    case parentThrough
    case buddyPass
    case buddyPassThrough
    case partnerPass
    case partnerPassThrough
    case lateShowGuest
    case lateShowGuestThrough
    case interlineGuest
    case interlineGuestThrough
    case reciprocalPilot
    case reciprocalPilotThrough
    case positiveSpace
    case unknown
    
    func typeDescription() -> String {
        switch self {
        case .deadHeadCrew:
            return NSLocalizedString("Standby.DeadHeadCrew", comment: "Standby.DeadHeadCrew")
        case .deadHeadCrewThrough:
            return NSLocalizedString("Standby.DeadHeadCrewThrough", comment: "Standby.DeadHeadCrewThrough")
        case .soldOutGuest:
            return NSLocalizedString("Standby.SoldOutGuest", comment: "Standby.SoldOutGuest")
        case .soldOutGuestThrough:
            return NSLocalizedString("Standby.SoldOutGuestThrough", comment: "Standby.SoldOutGuestThrough")
        case .employeeOnBusiness:
            return NSLocalizedString("Standby.EmployeeOnBusiness", comment: "Standby.EmployeeOnBusiness")
        case .employeeOnBusinessThrough:
            return NSLocalizedString("Standby.EmployeeOnBusinessThrough", comment: "Standby.EmployeeOnBusinessThrough")
        case .partnerAirlineEmployeeOnBusiness:
            return NSLocalizedString("Standby.PartnerAirlineEmployeeOnBusiness", comment: "Standby.PartnerAirlineEmployeeOnBusiness")
        case .partnerAirlineEmployeeOnBusinessThrough:
            return NSLocalizedString("Standby.PartnerAirlineEmployeeOnBusinessThrough", comment: "Standby.PartnerAirlineEmployeeOnBusinessThrough")
        case .earlyShowGuest:
            return NSLocalizedString("Standby.EarlyShowGuest", comment: "Standby.EarlyShowGuest")
        case .earlyShowGuestThrough:
            return NSLocalizedString("Standby.EarlyShowGuestThrough", comment: "Standby.EarlyShowGuestThrough")
        case .employeeOrDesignate:
            return NSLocalizedString("Standby.EmployeeOrDesignate", comment: "Standby.EmployeeOrDesignate")
        case .employeeOrDesignateThrough:
            return NSLocalizedString("Standby.EmployeeOrDesignateThrough", comment: "Standby.EmployeeOrDesignateThrough")
        case .earlyOutOrRetiree:
            return NSLocalizedString("Standby.EarlyOutOrRetiree", comment: "Standby.EarlyOutOrRetiree")
        case .earlyOutOrRetireeThrough:
            return NSLocalizedString("Standby.EarlyOutOrRetireeThrough", comment: "Standby.EarlyOutOrRetireeThrough")
        case .parent:
            return NSLocalizedString("Standby.Parent", comment: "Standby.Parent")
        case .parentThrough:
            return NSLocalizedString("Standby.ParentThrough", comment: "Standby.ParentThrough")
        case .buddyPass:
            return NSLocalizedString("Standby.BuddyPass", comment: "Standby.BuddyPass")
        case .buddyPassThrough:
            return NSLocalizedString("Standby.BuddyPassThrough", comment: "Standby.BuddyPassThrough")
        case .partnerPass:
            return NSLocalizedString("Standby.PartnerPass", comment: "Standby.PartnerPass")
        case .partnerPassThrough:
            return NSLocalizedString("Standby.PartnerPassThrough", comment: "Standby.PartnerPassThrough")
        case .lateShowGuest:
            return NSLocalizedString("Standby.LateShowGuest", comment: "Standby.LateShowGuest")
        case .lateShowGuestThrough:
            return NSLocalizedString("Standby.LateShowGuestThrough", comment: "Standby.LateShowGuestThrough")
        case .interlineGuest:
            return NSLocalizedString("Standby.InterlineGuest", comment: "Standby.InterlineGuest")
        case .interlineGuestThrough:
            return NSLocalizedString("Standby.InterlineGuestThrough", comment: "Standby.InterlineGuestThrough")
        case .reciprocalPilot:
            return NSLocalizedString("Standby.ReciprocalPilot", comment: "Standby.ReciprocalPilot")
        case .reciprocalPilotThrough:
            return NSLocalizedString("Standby.ReciprocalPilotThrough", comment: "Standby.ReciprocalPilotThrough")
        case .positiveSpace:
            return NSLocalizedString("Standby.PositiveSpace", comment: "Standby.PositiveSpace")
        default:
            return NSLocalizedString("Standby.Unknown", comment: "Standby.Unknown")
        }
    }
}

public struct Standby: Codable, FetchableRecord, MutablePersistableRecord {
    public let lid: String
    public let listed: String
    public let unsold: String
    public let cap: String
    public let priorityList: [StandbyBooking]
    
    private enum CodingKeys: String, CodingKey {
        case lid
        case listed = "nonrevs"
        case unsold = "available"
        case cap
        case priorityList
    }
    
    public init(lid: String, listed: String, unsold: String, cap: String, priorityList: [StandbyBooking]) {
        self.lid = lid
        self.listed = listed
        self.unsold = unsold
        self.cap = cap
        self.priorityList = priorityList
    }
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            lid = (try? values.decode(String.self, forKey: .lid)) ?? ""
            listed = (try? values.decode(String.self, forKey: .listed)) ?? ""
            unsold = (try? values.decode(String.self, forKey: .unsold)) ?? ""
            cap = (try? values.decode(String.self, forKey: .cap)) ?? ""
            priorityList = (try? values.decode([StandbyBooking].self, forKey: .priorityList)) ?? []
        } catch {
            NSLog("Failed to decode Standby: \(error)")
            throw error
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lid, forKey: .lid)
        try container.encode(listed, forKey: .listed)
        try container.encode(unsold, forKey: .unsold)
        try container.encode(cap, forKey: .cap)
        try container.encode(priorityList, forKey: .priorityList)
    }
}

public struct StandbyBooking: Codable, FetchableRecord, MutablePersistableRecord {
    public let firstName: String?
    public let lastName: String?
    public let classification: StandbyPriority
    
    public init(firstName: String?, lastName: String?, classification: StandbyPriority) {
        self.firstName = firstName
        self.lastName = lastName
        self.classification = classification
    }
}

public struct StandbyPriority: Codable, FetchableRecord, MutablePersistableRecord {
    public let originalCode: String // Only needed so we can transfer needed information to legacy WJStandbyPriority
    public let type: StandbyPriorityType
    
    public init(from decoder: Decoder) throws {
        do {
            let value = try decoder.singleValueContainer()
            originalCode = try value.decode(String.self)
            type = StandbyPriority.priorityTypeFromPriorityCode(originalCode)
        } catch {
            NSLog("Failed to decode StandbyPriority: \(error)")
            throw error
        }
    }
    
    public init(code: String) {
        originalCode = code
        type = StandbyPriority.priorityTypeFromPriorityCode(code)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(priorityCode)
    }
    
    static let showDetailsThreshold = StandbyPriorityType.parentThrough
    public func hasSufficientPriorityToDisplayDetails() -> Bool {
        if type.rawValue <= StandbyPriority.showDetailsThreshold.rawValue {
            return true
        }
        return false
    }
    
    public func isExcludedPriority() -> Bool {
        return type == .soldOutGuest ||
            type == .soldOutGuestThrough ||
            type == .employeeOnBusiness ||
            type == .employeeOnBusinessThrough ||
            type == .partnerAirlineEmployeeOnBusiness ||
            type == .partnerAirlineEmployeeOnBusinessThrough ||
            type == .earlyShowGuest ||
            type == .earlyShowGuestThrough
    }
    
    
    public var priorityCode: String {
        switch type {
        case .deadHeadCrew:
            return "1A"
        case .deadHeadCrewThrough:
            return "1AT"
        case .soldOutGuest:
            return "1B"
        case .soldOutGuestThrough:
            return "1BT"
        case .employeeOnBusiness:
            return "1C"
        case .employeeOnBusinessThrough:
            return "1CT"
        case .partnerAirlineEmployeeOnBusiness:
            return "1D"
        case .partnerAirlineEmployeeOnBusinessThrough:
            return "1DT"
        case .earlyShowGuest:
            return "2A"
        case .earlyShowGuestThrough:
            return "2AT"
        case .employeeOrDesignate:
            return "2B"
        case .employeeOrDesignateThrough:
            return "2BT"
        case .earlyOutOrRetiree:
            return "2D"
        case .earlyOutOrRetireeThrough:
            return "2DT"
        case .parent:
            return "3B"
        case .parentThrough:
            return "3BT"
        case .buddyPass:
            return "4B"
        case .buddyPassThrough:
            return "4BT"
        case .partnerPass:
            return "4C"
        case .partnerPassThrough:
            return "4CT"
        case .lateShowGuest:
            return "5A"
        case .lateShowGuestThrough:
            return "5AT"
        case .interlineGuest:
            return "5B"
        case .interlineGuestThrough:
            return "5BT"
        case .reciprocalPilot:
            return "7B"
        case .reciprocalPilotThrough:
            return "7BT"
        case .positiveSpace:
            return "PS"
        default:
            return ""
        }
    }
    
    static func priorityTypeFromPriorityCode(_ priorityCode: String) -> StandbyPriorityType {
        switch priorityCode {
        case "1A":
            return .deadHeadCrew
        case "1AT":
            return .deadHeadCrewThrough
        case "1B":
            return .soldOutGuest
        case "1BT":
            return .soldOutGuestThrough
        case "1C":
            return .employeeOnBusiness
        case "1CT":
            return .employeeOnBusinessThrough
        case "1D":
            return .partnerAirlineEmployeeOnBusiness
        case "1DT":
            return .partnerAirlineEmployeeOnBusinessThrough
        case "2A":
            return .earlyShowGuest
        case "2AT":
            return .earlyShowGuestThrough
        case "2B":
            return .employeeOrDesignate
        case "2BT":
            return .employeeOrDesignateThrough
        case "2D":
            return .earlyOutOrRetiree
        case "2DT":
            return .earlyOutOrRetireeThrough
        case "3B":
            return .parent
        case "3BT":
            return .parentThrough
        case "4B":
            return .buddyPass
        case "4BT":
            return .buddyPassThrough
        case "4C":
            return .partnerPass
        case "4CT":
            return .partnerPassThrough
        case "5A":
            return .lateShowGuest
        case "5AT":
            return .lateShowGuestThrough
        case "5B":
            return .interlineGuest
        case "5BT":
            return .interlineGuestThrough
        case "7B":
            return .reciprocalPilot
        case "7BT":
            return .reciprocalPilotThrough
        case "PS":
            return .positiveSpace
        default:
            NSLog("Unknown priority code: %@", priorityCode)
            return .unknown
        }
    }
}

/// Decodes an Int from either a JSON int type or a JSON string containing an Int.
struct IntAsPossibleStringJSONWrapper: Codable, FetchableRecord, MutablePersistableRecord {
    let int: Int
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // We previously supported decoding "durationMinutes" as an Int or a String. Not sure if this is still required though.
        if let intValue = try? container.decode(Int.self) {
            int = intValue
        } else if let stringValue = try? container.decode(String.self), let intValue = Int(stringValue) {
            int = intValue
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected an Int or a String containing an Int"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(int)
    }
}

public struct FlightStatusDetails: Codable, FetchableRecord, MutablePersistableRecord {
    static var databaseDateDecodingStrategry: DatabaseDateDecodingStrategy {
        return .iso8601
    }
    
    public static var databaseDateEncodingStrategy: DatabaseDateEncodingStrategy {
        return .iso8601
    }
    public let actualGateArrival: Date
    public let actualGateDeparture: Date
    public let arrivalAirportCode: String
    public let arrivalAirportName: String?
    public let arrivalCity: String?
    public let arrivalCountry: String?
    public let arrivalGate: String
    public let arrivalProvince: String?
    public let arrivalRegion: String?
    public let arrivalTerminal: String
    public let arrivalUTCRegion: String?
    public let arrivalTimeZone: TimeZone?
    public let arrivaldelay: Bool
    public let carrierCode: CarrierCode
    public let departureAirportCode: String
    public let departureAirportName: String?
    public let departureCity: String?
    public let departureCountry: String?
    public let departureGate: String
    public let departureProvince: String?
    public let departureRegion: String?
    public let departureTerminal: String
    public let departureUTCRegion: String?
    public let departureTimeZone: TimeZone?
    public let departuredelay: Bool
    public let estimatedGateArrival: Date?
    public let estimatedGateDeparture: Date?
    public let flightNumber: Int
    public let scheduledGateArrival: Date
    public let scheduledGateDeparture: Date
    public let statusCode: FlightStatusCode
    
    public struct Metadata: Codable, FetchableRecord, MutablePersistableRecord {
        public let fetchDate: Date?
        
        public init(fetchDate: Date?) {
            self.fetchDate = fetchDate
        }
    }
    public let metadata: Metadata
    
    enum CodingKeys: String, CodingKey {
        case actualGateArrival
        case actualGateDeparture
        case arrivalAirportCode
        case arrivalAirportName
        case arrivalCity
        case arrivalCountry
        case arrivalGate
        case arrivalProvince
        case arrivalRegion
        case arrivalTerminal
        case arrivalUTCRegion
        case arrivaldelay
        case carrierCode
        case departureAirportCode
        case departureAirportName
        case departureCity
        case departureCountry
        case departureGate
        case departureProvince
        case departureRegion
        case departureTerminal
        case departureUTCRegion
        case departuredelay
        case estimatedGateArrival
        case estimatedGateDeparture
        case flightNumber
        case scheduledGateArrival
        case scheduledGateDeparture
        case statusCode = "status"
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        actualGateArrival = try container.decode(Date.self, forKey: .actualGateArrival)
        actualGateDeparture = try container.decode(Date.self, forKey: .actualGateDeparture)
        arrivalAirportCode = try container.decode(String.self, forKey: .arrivalAirportCode)
        arrivalAirportName = try container.decodeIfPresent(String.self, forKey: .arrivalAirportName)
        arrivalCity = try container.decodeIfPresent(String.self, forKey: .arrivalCity)
        arrivalCountry = try container.decodeIfPresent(String.self, forKey: .arrivalCountry)
        arrivalGate = try container.decode(String.self, forKey: .arrivalGate)
        arrivalProvince = try container.decodeIfPresent(String.self, forKey: .arrivalProvince)
        arrivalRegion = try container.decodeIfPresent(String.self, forKey: .arrivalRegion)
        arrivalTerminal = try container.decode(String.self, forKey: .arrivalTerminal)
        arrivalUTCRegion = try container.decodeIfPresent(String.self, forKey: .arrivalUTCRegion)
        if let arrivalUTCRegion = arrivalUTCRegion {
            if let value = TimeZone(identifier: arrivalUTCRegion) {
                arrivalTimeZone = value
            } else {
                // have a timezone value but failed to convert it
                throw DecodingError.typeMismatch(TimeZone.self, DecodingError.Context.init(codingPath: [CodingKeys.arrivalUTCRegion], debugDescription: "Unable to decode value as TimeZone"))
            }
        } else {
            arrivalTimeZone = nil
        }
        let arrivalString = try container.decode(String.self, forKey: .arrivaldelay).lowercased()
        switch arrivalString {
        case "1", "true":
            arrivaldelay = true
        default:
            arrivaldelay = false
        }
        carrierCode = try container.decode(CarrierCode.self, forKey: .carrierCode)
        departureAirportCode = try container.decode(String.self, forKey: .departureAirportCode)
        departureAirportName = try container.decode(String.self, forKey: .departureAirportName)
        departureCity = try container.decode(String.self, forKey: .departureCity)
        departureCountry = try container.decode(String.self, forKey: .departureCountry)
        departureGate = try container.decode(String.self, forKey: .departureGate)
        departureProvince = try container.decode(String.self, forKey: .departureProvince)
        departureRegion = try container.decode(String.self, forKey: .departureRegion)
        departureTerminal = try container.decode(String.self, forKey: .departureTerminal)
        departureUTCRegion = try container.decode(String.self, forKey: .departureUTCRegion)
        if let departureUTCRegion = departureUTCRegion {
            if let value = TimeZone(identifier: departureUTCRegion) {
                departureTimeZone = value
            } else {
                // have a timezone value but failed to convert it
                throw DecodingError.typeMismatch(TimeZone.self, DecodingError.Context.init(codingPath: [CodingKeys.departureUTCRegion], debugDescription: "Unable to decode value as TimeZone"))
            }
        } else {
            departureTimeZone = nil
        }
        let departureString = try container.decode(String.self, forKey: .departuredelay).lowercased()
        switch departureString {
        case "1", "true":
            departuredelay = true
        default:
            departuredelay = false
        }
        estimatedGateArrival = try container.decode(Date.self, forKey: .estimatedGateArrival)
        estimatedGateDeparture = try container.decode(Date.self, forKey: .estimatedGateDeparture)
        let flightNumberString = try container.decodeIfPresent(String.self, forKey: .flightNumber)
        if let flightNumberString = flightNumberString, let value = Int(flightNumberString) {
            flightNumber = value
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context.init(codingPath: [CodingKeys.flightNumber], debugDescription: "Unable to decode value as Int"))
        }
        scheduledGateArrival = try container.decode(Date.self, forKey: .scheduledGateArrival)
        scheduledGateDeparture = try container.decode(Date.self, forKey: .scheduledGateDeparture)
        statusCode = try container.decode(FlightStatusCode.self, forKey: .statusCode)
        
        // When decoding from API JSON we won't have metadata and use appropriate defaults
        // When decoding from local storage we want to use our saved metadata
        metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata) ?? Metadata(fetchDate: Date())
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(actualGateArrival, forKey: .actualGateArrival)
        try container.encode(actualGateDeparture, forKey: .actualGateDeparture)
        try container.encode(arrivalAirportCode, forKey: .arrivalAirportCode)
        try container.encode(arrivalAirportName, forKey: .arrivalAirportName)
        try container.encode(arrivalCity, forKey: .arrivalCity)
        try container.encode(arrivalCountry, forKey: .arrivalCountry)
        try container.encode(arrivalGate, forKey: .arrivalGate)
        try container.encode(arrivalProvince, forKey: .arrivalProvince)
        try container.encode(arrivalRegion, forKey: .arrivalRegion)
        try container.encode(arrivalTerminal, forKey: .arrivalTerminal)
        try container.encode(arrivalUTCRegion, forKey: .arrivalUTCRegion)
        try container.encode(arrivaldelay, forKey: .arrivaldelay)
        try container.encode(carrierCode, forKey: .carrierCode)
        try container.encode(departureAirportCode, forKey: .departureAirportCode)
        try container.encode(departureAirportName, forKey: .departureAirportName)
        try container.encode(departureCity, forKey: .departureCity)
        try container.encode(departureCountry, forKey: .departureCountry)
        try container.encode(departureGate, forKey: .departureGate)
        try container.encode(departureProvince, forKey: .departureProvince)
        try container.encode(departureRegion, forKey: .departureRegion)
        try container.encode(departureTerminal, forKey: .departureTerminal)
        try container.encode(departureUTCRegion, forKey: .departureUTCRegion)
        try container.encode(departuredelay, forKey: .departuredelay)
        try container.encode(estimatedGateArrival, forKey: .estimatedGateArrival)
        try container.encode(estimatedGateDeparture, forKey: .estimatedGateDeparture)
        try container.encode(flightNumber, forKey: .flightNumber)
        try container.encode(scheduledGateArrival, forKey: .scheduledGateArrival)
        try container.encode(scheduledGateDeparture, forKey: .scheduledGateDeparture)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(metadata, forKey: .metadata)
    }
    
    public init(
        actualGateArrival: Date,
        actualGateDeparture: Date,
        arrivalAirportCode: String,
        arrivalAirportName: String?,
        arrivalCity: String?,
        arrivalCountry: String?,
        arrivalGate: String,
        arrivalProvince: String?,
        arrivalRegion: String?,
        arrivalTerminal: String,
        arrivalUTCRegion: String?,
        arrivalTimeZone: TimeZone?,
        arrivaldelay: Bool,
        carrierCode: CarrierCode,
        departureAirportCode: String,
        departureAirportName: String?,
        departureCity: String?,
        departureCountry: String?,
        departureGate: String,
        departureProvince: String?,
        departureRegion: String?,
        departureTerminal: String,
        departureUTCRegion: String?,
        departureTimeZone: TimeZone?,
        departuredelay: Bool,
        estimatedGateArrival: Date?,
        estimatedGateDeparture: Date?,
        flightNumber: Int,
        scheduledGateArrival: Date,
        scheduledGateDeparture: Date,
        statusCode: FlightStatusCode,
        metadata: Metadata
        ) {
        self.actualGateArrival = actualGateArrival
        self.actualGateDeparture = actualGateDeparture
        self.arrivalAirportCode = arrivalAirportCode
        self.arrivalAirportName = arrivalAirportName
        self.arrivalCity = arrivalCity
        self.arrivalCountry = arrivalCountry
        self.arrivalGate = arrivalGate
        self.arrivalProvince = arrivalProvince
        self.arrivalRegion = arrivalRegion
        self.arrivalTerminal = arrivalTerminal
        self.arrivalUTCRegion = arrivalUTCRegion
        self.arrivalTimeZone = arrivalTimeZone
        self.arrivaldelay = arrivaldelay
        self.carrierCode = carrierCode
        self.departureAirportCode = departureAirportCode
        self.departureAirportName = departureAirportName
        self.departureCity = departureCity
        self.departureCountry = departureCountry
        self.departureGate = departureGate
        self.departureProvince = departureProvince
        self.departureRegion = departureRegion
        self.departureTerminal = departureTerminal
        self.departureUTCRegion = departureUTCRegion
        self.departureTimeZone = departureTimeZone
        self.departuredelay = departuredelay
        self.estimatedGateArrival = estimatedGateArrival
        self.estimatedGateDeparture = estimatedGateDeparture
        self.flightNumber = flightNumber
        self.scheduledGateArrival = scheduledGateArrival
        self.scheduledGateDeparture = scheduledGateDeparture
        self.statusCode = statusCode
        self.metadata = metadata
    }
    
}

public enum FlightStatusCode: String, Codable, FetchableRecord, MutablePersistableRecord {
    case cancelled = "C"
    case landed = "L"
    case scheduled = "S"
    case active = "A"
}

public struct CarrierCode: Equatable, Codable, FetchableRecord, MutablePersistableRecord, RawRepresentable {
    public var code: String
    
    public init?(rawValue: String) {
        code = rawValue
    }
    
    public var rawValue: String {
        return code
    }
    
    var isWestJet: Bool {
        return code.lowercased() == "ws"
    }
}
