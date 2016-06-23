//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import Foundation

public typealias WaxwingMigrationBlock = () -> Void

public class Waxwing {

    private let migratedToKey = "com.schnaub.Waxwing.migratedTo"
    private let migrationQueue = "com.schnaub.Waxwing.queue"

    private let bundle: Bundle
    private let defaults: UserDefaults
    private var progress: Progress

    public init(bundle: Bundle, defaults: UserDefaults) {
        self.bundle = bundle
        self.defaults = defaults
        
        progress = Progress()
        progress.isPausable = false
        progress.isCancellable = false
    }
    
    public func migrateToVersion(_ version: String, migrationBlock: WaxwingMigrationBlock) {
        if canUpdateTo(version) {
            progress.totalUnitCount = 1
            migrationBlock()
            migratedTo(version)
            progress.completedUnitCount = 1
        }
    }
    
    public func migrateToVersion(_ version: String, migrations: [Operation]) {
        if canUpdateTo(version) && !migrations.isEmpty {
            progress.totalUnitCount = Int64(migrations.count)

            let queue = OperationQueue()
            queue.underlyingQueue = DispatchQueue(label: migrationQueue, attributes: DispatchQueueAttributes.concurrent)
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

    private func canUpdateTo(_ version: NSString) -> Bool {
        return version.compare(migratedTo(), options: .numericSearch) == ComparisonResult.orderedDescending
            && version.compare(appVersion(), options: .numericSearch) != ComparisonResult.orderedDescending
    }
    
    private func migratedTo() -> String {
        let migratedTo = defaults.value(forKey: migratedToKey) as? String
        progress.completedUnitCount += 1
        return migratedTo ?? ""
    }
    
    private func migratedTo(_ version: String) {
        defaults.setValue(version, forKey: migratedToKey)
        defaults.synchronize()
    }
    
    private func appVersion() -> String {
        return bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    }
    
    private class DidMigrateOperation: Operation {
        
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
    
    private class ProgressCounter: Operation {

        let progress: Progress
        
        init(progress: Progress) {
            self.progress = progress
        }
        
        override func start() {
            progress.completedUnitCount += 1
        }

    }
    
}
