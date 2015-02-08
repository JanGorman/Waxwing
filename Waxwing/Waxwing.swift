//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import Foundation

public typealias WaxwingMigrationBlock = () -> Void

public struct Waxwing {

    private static let migratedToKey = "com.schnaub.Waxwing.migratedTo"
    private static let migrationQueue = "com.schnaub.Waxwing.queue"

    private static var appVersion: String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String
    }

    private static var defaults: NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }

    public static func migrateToVersion(version: String, migrationBlock: WaxwingMigrationBlock) {
        if canUpdateTo(version) {
            migrationBlock()
            migratedTo(version)
        }
    }

    public static func migrateToVersion(version: String, migrations: [NSOperation]) {
        if canUpdateTo(version) {
            let queue = NSOperationQueue()
            queue.underlyingQueue = dispatch_queue_create(migrationQueue, DISPATCH_QUEUE_CONCURRENT)

            let didMigrateOperation = DidMigrateOperation(version: version)
            didMigrateOperation.addDependency(migrations.last!)
            queue.addOperation(didMigrateOperation)

            queue.addOperations(migrations, waitUntilFinished: true)
        }
    }

    private static func canUpdateTo(version: NSString) -> Bool {
        return version.compare(migratedTo(), options: .NumericSearch) == NSComparisonResult.OrderedDescending
                && version.compare(appVersion, options: .NumericSearch) != NSComparisonResult.OrderedDescending
    }

    private static func migratedTo() -> String {
        let migratedTo = defaults.valueForKey(migratedToKey) as? String
        return migratedTo ?? ""
    }

    private static func migratedTo(version: String) {
        defaults.setValue(version, forKey: migratedToKey)
        defaults.synchronize()
    }

    class DidMigrateOperation: NSOperation {

        let version: String

        init(version: String) {
            self.version = version
        }

        override func start() {
            Waxwing.migratedTo(version)
        }

    }

}
