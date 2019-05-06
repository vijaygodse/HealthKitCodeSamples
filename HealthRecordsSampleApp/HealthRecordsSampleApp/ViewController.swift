//
//  ViewController.swift
//  HealthRecordsSampleApp
//
//  Created by Vijay Godse on 2/14/19.
//  Copyright © 2019 iOS dev 7. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    var clinicalTypes =  Set<HKClinicalType>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let allergiesType = HKObjectType.clinicalType(forIdentifier: .allergyRecord),
            let medicationsType = HKObjectType.clinicalType(forIdentifier: .medicationRecord),
            let conditionRecord = HKObjectType.clinicalType(forIdentifier: .conditionRecord),
            let immunizationRecord = HKObjectType.clinicalType(forIdentifier: .immunizationRecord),
            let labResultRecord = HKObjectType.clinicalType(forIdentifier: .labResultRecord),
            let procedureRecord = HKObjectType.clinicalType(forIdentifier: .procedureRecord),
            let vitalSignRecord = HKObjectType.clinicalType(forIdentifier: .vitalSignRecord) else {
                fatalError("*** Unable to create the requested types ***")
        }
        
        clinicalTypes = [allergiesType, medicationsType, conditionRecord, immunizationRecord, labResultRecord, procedureRecord, vitalSignRecord]
        
        authorizeHealthRecord(for: clinicalTypes)
        
    }
    
    private func authorizeHealthRecord(for types: Set<HKSampleType>) {
        
        // Clinical types are read-only.
        healthStore.requestAuthorization(toShare: nil, read: types) { (success, error) in
            
            guard success else {
                // Handle errors here.
                fatalError("*** An error occurred while requesting authorization: \(error!.localizedDescription) ***")
            }
            
            // You can start accessing clinical record data.
        }
    }
    
    
    
    @IBAction func fetchData(_ sender: Any) {
        
        
        clinicalTypes.forEach { (clinicalType) in
            
            let sampleQuery = HKSampleQuery(sampleType: clinicalType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                
                guard let actualSamples = samples else {
                    // Handle the error here.
                    print("*** An error occurred: \(error?.localizedDescription ?? "nil") ***")
                    return
                }
                
                let samples = actualSamples as? [HKClinicalRecord]
                // Do something with the allergy samples here...
                
                
                samples?.forEach({ (clinicalRecord) in
                    
                    guard let fhirRecord = clinicalRecord.fhirResource else {
                        print("No FHIR record found!")
                        return
                    }
                    
                    do {
                        let jsonDictionary = try JSONSerialization.jsonObject(with: fhirRecord.data, options: [])
                        
                        // Do something with the JSON data here.
                        print("------------\(clinicalRecord.clinicalType)--------------")
                        print("clinicalType: \(clinicalRecord.clinicalType)")
                        print("displayName: \(clinicalRecord.displayName)")
                        print("device: \(String(describing: clinicalRecord.device))")
                        print("endDate: \(clinicalRecord.endDate)")
                        print("startDate: \(clinicalRecord.startDate)")
                        print("uuid: \(clinicalRecord.uuid)")
                        print("sourceRevision: \(clinicalRecord.sourceRevision)")
                        print("metadata: \(String(describing: clinicalRecord.metadata))")
                        print("fhir....")
                        print(" identifier: \(fhirRecord.identifier)")
                        print(" resourceType: \(fhirRecord.resourceType)")
                        print(" sourceURL: \(String(describing: fhirRecord.sourceURL))")
                        print(" fhirResource JSON:\n \(jsonDictionary)")
                        print("--------------------------------------------------------")
                        
                    }
                    catch let error {
                        print("*** An error occurred while parsing the FHIR data: \(error.localizedDescription) ***")
                        // Handle JSON parse errors here.
                    }
                })
                
            }
            
            healthStore.execute(sampleQuery)
        }
        
    }
    
    
    
}

