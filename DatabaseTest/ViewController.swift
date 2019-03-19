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
        let alert = UIAlertController(title: "Add Trip", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "PNR"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
        }
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
            guard
                let PNR = alert.textFields?[0].text,
                let name = alert.textFields?[1].text
            else {
                return
            }
            
            DataSource.shared.addTrip(Trip(PNR: PNR, name: name))
        }))
        
        present(alert, animated: true, completion: nil)
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
                cell.nameLabel.text = trips[indexPath.item].name
                cell.pnrLabel.text = trips[indexPath.item].PNR
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
