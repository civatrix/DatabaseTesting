//
//  ViewController.swift
//  DatabaseTest
//
//  Created by Daniel Johns on 2019-03-19.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit
import DatabaseTestKit

class ViewController: UIViewController {
    var trips = [Trip]()
    
    @IBOutlet var tripsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        DataSource.shared.registerForUpdates(self)
        trips = DataSource.shared.trips()
    }
    
    func addTrip() {
        do {
            guard let url = Bundle.main.url(forResource: "trip", withExtension: "json") else { return }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let trip = try decoder.decode(Trip.self, from: data)
            DataSource.shared.addTrip(trip)
        } catch {
            NSLog("\(error)")
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item == trips.count {
            return tableView.dequeueReusableCell(withIdentifier: "AddTrip", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)
            
            if let cell = cell as? TripCell {
                cell.pnrLabel.text = trips[indexPath.item].passengerNameRecord
            }
            
            return cell
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.item == trips.count else { return }
        
        addTrip()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.item == trips.count {
            return .none
        } else {
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        DataSource.shared.removeTrip(at: indexPath.item)
    }
}

extension ViewController: DataUpdateListener {
    func tripsUpdated(trips: [Trip]) {
        self.trips = trips
        tripsTableView.reloadData()
    }
}

class TripCell: UITableViewCell {
    @IBOutlet var pnrLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
}
