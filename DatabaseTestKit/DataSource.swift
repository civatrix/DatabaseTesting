//
//  DataSource.swift
//  DatabaseTest
//
//  Created by Daniel Johns on 2019-03-19.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit
import PromiseKit
import GRDB

public protocol DataUpdateListener: class {
    func tripsUpdated(trips: [Trip])
}

public struct Trip: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
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
    
    private let databaseQueue: DatabaseQueue
    private let fileUrl = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.databasetest")!.appendingPathComponent("database.sqlite")
    // We need a new NSFileCoordinator for each transaction
    public var coordinator: NSFileCoordinator {
        return NSFileCoordinator(filePresenter: self)
    }
    
    override init() {
        databaseQueue = try! DatabaseQueue(path: fileUrl.relativePath)
        
        super.init()
        
        createDatabase()
        refreshData()
    }
    
    private func createDatabase() {
        do {
            try databaseQueue.write { db in
                try db.create(table: "trip", temporary: false, ifNotExists: true) { table in
                    table.autoIncrementedPrimaryKey("id")
                    table.column("PNR", .text)
                    table.column("name", .text)
                }
            }
        } catch {
            NSLog("Failed to create table: \(error)")
        }
    }
    
    @discardableResult
    public func refreshData() -> Promise<[Trip]> {
        let (promise, seal) = Promise<[Trip]>.pending()
        coordinator.coordinate(readingItemAt: fileUrl, options: .withoutChanges, error: nil) { (url) in
            do {
                tripsStore = try databaseQueue.read() { db -> [Trip] in
                    return try Trip.fetchAll(db)
                }
                seal.fulfill(tripsStore)
            } catch {
                NSLog("Unable to read database: \(error)")
                seal.reject(error)
            }
        }
        
        return promise
    }
    
    public func trips() -> [Trip] {
        return tripsStore
    }
    
    public func addTrip(_ trip: Trip) {
        coordinator.coordinate(writingItemAt: fileUrl, options: .forReplacing, error: nil) { (url) in
            do {
                try databaseQueue.write() { db in
                    var newTrip = trip
                    try newTrip.insert(db)
                    tripsStore.append(newTrip)
                }
            } catch {
                NSLog("Failed to serialize trips to database: \(error)")
            }
        }
    }
    
    public func removeTrip(at index: Int) {
        let trip = tripsStore.remove(at: index)
        coordinator.coordinate(writingItemAt: fileUrl, options: .forReplacing, error: nil) { (url) in
            do {
                _=try databaseQueue.write() { db in
                    try trip.delete(db)
                }
            } catch {
                NSLog("Failed to delete trip from database: \(error)")
            }
        }
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
