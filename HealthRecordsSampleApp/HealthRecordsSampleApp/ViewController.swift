//
//  ViewController.swift
//  HealthRecordsSampleApp
//
//  Created by Vijay Godse on 2/14/19.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    var clinicalTypes =  Set<HKClinicalType>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    

    @IBAction func authorize(_ sender: Any) {
        
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
    
    
    @IBAction func fetchData(_ sender: Any) {
        
        
        clinicalTypes.forEach { (clinicalType) in
            
//            self.fetchDataUsingSampleQuery(sampleType: clinicalType)
            self.fetchDataUsingAnchoredQuery(sampleType: clinicalType)
            
        }
        
    }
    
    
    private func authorizeHealthRecord(for types: Set<HKSampleType>) {
        
        // Clinical types are read-only.
        healthStore.requestAuthorization(toShare: nil, read: types) { (success, error) in
            
            guard success else {
                // Handle errors here.
                fatalError("*** An error occurred while requesting authorization: \(error!.localizedDescription) ***")
            }
            
            self.enableBackgroundUpdates(for: types)
        }
    }
    
    private func enableBackgroundUpdates(for types: Set<HKSampleType>) {
        for objectType in types {
            
            HKHealthStore().enableBackgroundDelivery(for: objectType, frequency: .immediate) { (isEnabledBackgroundUpdates, error) in
                
                if isEnabledBackgroundUpdates {
                    Logger.shared.write("Background Updates Enabled for type: \(objectType)")
                }
            }
        }
    }
    
    private func fetchDataUsingSampleQuery(sampleType: HKClinicalType) {
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            self.getData(samples: samples, error: error)
            
        }
        
        healthStore.execute(sampleQuery)
    }
    
    
    private func fetchDataUsingAnchoredQuery(sampleType: HKClinicalType) {
        
        var anchor = HKQueryAnchor.init(fromValue: 0)
        
        //        if let object = KeychainWrapper.standard.object(forKey: "Anchor") {
        //            anchor = object as! HKQueryAnchor
        //        }
        
        
        let query = HKAnchoredObjectQuery(type: sampleType,
                                          predicate: nil,
                                          anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
                                            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
                                                fatalError("*** An error occurred during the initial query: \(errorOrNil!.localizedDescription) ***")
                                            }
                                            
                                           
                                            self.getData(samples: samplesOrNil, error: errorOrNil)
                                            Logger.shared.write("-------------------------------------------------")
                                            
                                            Logger.shared.write("Anchor query executed")
                                            Logger.shared.write("Record receive time \(Date())")
                                            
                                            
                                            anchor = newAnchor!
                                            
                                            //                                            let data : Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
                                            //
                                            //                                            let _: Bool = KeychainWrapper.standard.set(data, forKey: "Anchor")
                                            
                                            
                                            
                                            Logger.shared.write("Sample count: \(samples.count)")
                                            
                                            for resultSample in samples {
                                                Logger.shared.write("Samples: \(resultSample)")
                                            }
                                            
                                            for deletedSample in deletedObjects {
                                                Logger.shared.write("deleted: \(deletedSample)")
                                            }
                                            
                                            Logger.shared.write("Anchor: \(anchor)")
                                            Logger.shared.write("-------------------------------------------------")
                                            
        }
        
        
        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            Logger.shared.write("-------------------------------------------------")
            Logger.shared.write("Anchor query update handler executed")
            Logger.shared.write("Record receive time \(Date())")
            
            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
                // Handle the error here.
                fatalError("*** An error occurred during an update: \(errorOrNil!.localizedDescription) ***")
            }
            
            
            self.getData(samples: samplesOrNil, error: errorOrNil)
            
            anchor = newAnchor!
            //            let data : Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
            //            let _: Bool = KeychainWrapper.standard.set(data, forKey: "Anchor")
            
            //            if saveSuccessful {
            //                Logger.shared.write("Anchor saved to keychain")
            //            } else {
            //                Logger.shared.write("Saving anchor to keychain failed")
            //            }
            
            Logger.shared.write("Updated Sample count: \(samples.count)")
            
            for resultSample in samples {
                Logger.shared.write("samples: \(resultSample)")
            }
            
            for deletedSample in deletedObjects {
                Logger.shared.write("deleted: \(deletedSample)")
            }
            
            Logger.shared.write("-------------------------------------------------")
            
        }
        
        healthStore.execute(query)
    }
    
    
    private func getData(samples: [HKSample]?, error: Error?) {
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
                Logger.shared.write("------------\(clinicalRecord.clinicalType)--------------")
                Logger.shared.write("clinicalType: \(clinicalRecord.clinicalType)")
                Logger.shared.write("displayName: \(clinicalRecord.displayName)")
                Logger.shared.write("device: \(String(describing: clinicalRecord.device))")
                Logger.shared.write("endDate: \(clinicalRecord.endDate)")
                Logger.shared.write("startDate: \(clinicalRecord.startDate)")
                Logger.shared.write("uuid: \(clinicalRecord.uuid)")
                Logger.shared.write("sourceRevision: \(clinicalRecord.sourceRevision)")
                Logger.shared.write("metadata: \(String(describing: clinicalRecord.metadata))")
                Logger.shared.write("fhir....")
                Logger.shared.write(" identifier: \(fhirRecord.identifier)")
                Logger.shared.write(" resourceType: \(fhirRecord.resourceType)")
                Logger.shared.write(" sourceURL: \(String(describing: fhirRecord.sourceURL))")
                Logger.shared.write(" fhirResource JSON:\n \(jsonDictionary)")
                Logger.shared.write("--------------------------------------------------------")
                
            }
            catch let error {
                print("*** An error occurred while parsing the FHIR data: \(error.localizedDescription) ***")
                // Handle JSON parse errors here.
            }
        })
    }
    
    
    
}
