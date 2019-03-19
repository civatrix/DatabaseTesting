//
//  DataSource.swift
//  DatabaseTest
//
//  Created by Daniel Johns on 2019-03-19.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit

public protocol DataUpdateListener: class {
    func tripsUpdated(trips: [Trip])
}

public struct Trip: Codable {
    public let PNR: String
    public let name: String
    
    public init(PNR: String, name: String) {
        self.PNR = PNR
        self.name = name
    }
}

public class DataSource {
    public static let shared = DataSource()
    
    private var listeners = [ObjectIdentifier: DataUpdateListener]()
    private var tripsStore = [Trip]() {
        didSet {
            tripsUpdated()
        }
    }
    
    private func refreshData() {
        
    }
    
    public func trips() -> [Trip] {
        return tripsStore
    }
    
    public func addTrip(_ trip: Trip) {
        tripsStore.append(trip)
    }
    
    public func removeTrip(at index: Int) {
        tripsStore.remove(at: index)
    }
    
    public func registerForUpdates(_ listener: DataUpdateListener) {
        listeners[ObjectIdentifier(listener)] = listener
    }
    
    public func unregisterForUpdates(_ listener: DataUpdateListener) {
        listeners.removeValue(forKey: ObjectIdentifier(listener))
    }
    
    private func tripsUpdated() {
        let newTrips = trips()
        listeners.values.forEach { $0.tripsUpdated(trips: newTrips) }
    }
}
