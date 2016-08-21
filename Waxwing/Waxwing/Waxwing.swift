//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import Foundation

public typealias WaxwingMigrationBlock = () -> Void

final class Waxwing {

    fileprivate let migratedToKey = "com.schnaub.Waxwing.migratedTo"
    fileprivate let migrationQueue = "com.schnaub.Waxwing.queue"

    fileprivate let bundle: Bundle
    fileprivate let defaults: UserDefaults
    fileprivate var progress: Progress

    public init(bundle: Bundle, defaults: UserDefaults) {
        self.bundle = bundle
        self.defaults = defaults
        
        progress = Progress()
        progress.isPausable = false
        progress.isCancellable = false
    }
    
    open func migrateToVersion(_ version: String, migrationBlock: WaxwingMigrationBlock) {
        if canUpdateTo(version as NSString) {
            progress.totalUnitCount = 1
            migrationBlock()
            migratedTo(version)
            progress.completedUnitCount = 1
        }
    }
    
    open func migrateToVersion(_ version: String, migrations: [Operation]) {
        if canUpdateTo(version as NSString) && !migrations.isEmpty {
            progress.totalUnitCount = Int64(migrations.count)

            let queue = OperationQueue()
            queue.underlyingQueue = DispatchQueue(label: migrationQueue, attributes: .concurrent)
            for migration in migrations {
                let counter = ProgressCounter(progress: progress)
                counter.addDependency(migration)
                queue.addOperation(counter)
            }

            let didMigrateOperation = DidMigrateOperation(waxwing: self, version: version)
            didMigrateOperation.addDependency(migrations.last!)
            queue.addOperation(didMigrateOperation)
            
            queue.addOperations(migrations, waitUntilFinished: true)
        }
    }

    fileprivate func canUpdateTo(_ version: NSString) -> Bool {
        return version.compare(migratedTo(), options: .numeric) == .orderedDescending
            && version.compare(appVersion(), options: .numeric) != .orderedDescending
    }
    
    fileprivate func migratedTo() -> String {
        let migratedTo = defaults.string(forKey: migratedToKey)
        progress.completedUnitCount += 1
        return migratedTo ?? ""
    }
    
    fileprivate func migratedTo(_ version: String) {
        defaults.set(version, forKey: migratedToKey)
        defaults.synchronize()
    }
    
    fileprivate func appVersion() -> String {
        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    fileprivate class DidMigrateOperation: Operation {
        
        let waxwing: Waxwing
        let version: String
        
        init(waxwing: Waxwing, version: String) {
            self.waxwing = waxwing
            self.version = version
        }
        
        override func start() {
            waxwing.migratedTo(version)
        }
        
    }
    
    fileprivate class ProgressCounter: Operation {

        let progress: Progress
        
        init(progress: Progress) {
            self.progress = progress
        }
        
        override func start() {
            progress.completedUnitCount += 1
        }

    }
    
}
