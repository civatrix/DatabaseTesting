//
//  TodayViewController.swift
//  DatabaseTestUpcomingToday
//
//  Created by Daniel Johns on 2019-03-21.
//  Copyright © 2019 WestJet Airlines Ltd. All rights reserved.
//

import UIKit
import NotificationCenter
import DatabaseTestKit

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var tripLabel: UILabel!
    var upcomingTrip: Trip? {
        didSet {
            if let trip = upcomingTrip {
                tripLabel.text = trip.passengerNameRecord
            } else {
                tripLabel.text = "No upcoming trips"
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        upcomingTrip = DataSource.shared.trips().first
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DataSource.shared.registerForUpdates(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DataSource.shared.unregisterForUpdates(self)
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        DataSource.shared.refreshData().done { newTrips in
            self.upcomingTrip = newTrips.first
            completionHandler(.newData)
        }.catch { (_) in
            completionHandler(.failed)
        }
    }
}

extension TodayViewController: DataUpdateListener {
    func tripsUpdated(trips: [Trip]) {
        upcomingTrip = trips.first
    }
}
