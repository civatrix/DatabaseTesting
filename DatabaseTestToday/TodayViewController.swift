//
//  TodayViewController.swift
//  DatabaseTestToday
//
//  Created by Daniel Johns on 2019-03-19.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit
import NotificationCenter
import DatabaseTestKit

class TodayViewController: UIViewController, NCWidgetProviding {
    var trips = [Trip]() {
        didSet {
            tripsTableView.reloadData()
        }
    }
    
    @IBOutlet var tripsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        trips = DataSource.shared.trips()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DataSource.shared.registerForUpdates(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DataSource.shared.unregisterForUpdates(self)
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        DataSource.shared.refreshData().done { newTrips in
            self.trips = newTrips
            completionHandler(.newData)
        }.catch { (_) in
            completionHandler(.failed)
        }
    }
    
    func addTrip() {
        
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        preferredContentSize = maxSize
    }
}

extension TodayViewController: UITableViewDataSource {
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

extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == trips.count {
            addTrip()
        } else {
            DataSource.shared.removeTrip(at: indexPath.item)
        }
    }
}

extension TodayViewController: DataUpdateListener {
    func tripsUpdated(trips: [Trip]) {
        self.trips = trips
    }
}

class TripCell: UITableViewCell {
    @IBOutlet var pnrLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
}
