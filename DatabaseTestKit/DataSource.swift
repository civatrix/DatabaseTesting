//
//  DataSource.swift
//  DatabaseTest
//
//  Created by Daniel Johns on 2019-03-19.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit
import PromiseKit

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

public class DataSource: NSObject {
    public static let shared = DataSource()
    
    private var listeners = [ObjectIdentifier: DataUpdateListener]() {
        didSet {
            if listeners.isEmpty {
                NSFileCoordinator.removeFilePresenter(self)
            } else {
                NSFileCoordinator.addFilePresenter(self)
            }
        }
    }
    private var tripsStore = [Trip]() {
        didSet {
            tripsUpdated()
        }
    }
    
    private let fileUrl = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.databasetest")!.appendingPathComponent("database")
    // We need a new NSFileCoordinator for each transaction
    public var coordinator: NSFileCoordinator {
        return NSFileCoordinator(filePresenter: self)
    }
    
    override init() {
        super.init()
        
        refreshData()
    }
    
    @discardableResult
    public func refreshData() -> Promise<[Trip]> {
        let (promise, seal) = Promise<[Trip]>.pending()
        coordinator.coordinate(readingItemAt: fileUrl, options: .withoutChanges, error: nil) { (url) in
            do {
                let data = try Data(contentsOf: url)
                tripsStore = try JSONDecoder().decode([Trip].self, from: data)
                seal.fulfill(tripsStore)
            } catch {
                NSLog("Unable to deserialize database: \(error)")
                seal.reject(error)
            }
        }
        
        return promise
    }
    
    public func trips() -> [Trip] {
        return tripsStore
    }
    
    public func addTrip(_ trip: Trip) {
        tripsStore.append(trip)
        saveTrips()
    }
    
    public func removeTrip(at index: Int) {
        tripsStore.remove(at: index)
        saveTrips()
    }
    
    public func registerForUpdates(_ listener: DataUpdateListener) {
        listeners[ObjectIdentifier(listener)] = listener
    }
    
    public func unregisterForUpdates(_ listener: DataUpdateListener) {
        listeners.removeValue(forKey: ObjectIdentifier(listener))
    }
    
    private func saveTrips() {
        coordinator.coordinate(writingItemAt: fileUrl, options: .forReplacing, error: nil) { (url) in
            do {
                try JSONEncoder().encode(tripsStore).write(to: url)
            } catch {
                NSLog("Failed to serialize trips to database: \(error)")
            }
        }
    }
    
    private func tripsUpdated() {
        let newTrips = trips()
        listeners.values.forEach { $0.tripsUpdated(trips: newTrips) }
    }
}

extension DataSource: NSFilePresenter {
    public var presentedItemURL: URL? {
        return fileUrl
    }
    
    public var presentedItemOperationQueue: OperationQueue {
        return OperationQueue.main
    }
    
    public func presentedItemDidChange() {
        DispatchQueue.main.async {
            self.refreshData()
        }
    }
}
