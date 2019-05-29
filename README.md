[![Build Status](https://travis-ci.org/JanGorman/Waxwing.svg?branch=master)](https://travis-ci.org/JanGorman/Waxwing)
[![codecov](https://codecov.io/gh/JanGorman/Waxwing/branch/master/graph/badge.svg)](https://codecov.io/gh/JanGorman/Waxwing)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Waxwing.svg?style=flat)](http://cocoapods.org/pods/Waxwing)
[![License](https://img.shields.io/cocoapods/l/Waxwing.svg?style=flat)](http://cocoapods.org/pods/Waxwing)
[![Platform](https://img.shields.io/cocoapods/p/Waxwing.svg?style=flat)](http://cocoapods.org/pods/Waxwing)

# Waxwing

iOS version migrations in Swift. When mangling data or performing any other kind of updates you want to ensure that all relevant migrations are run in order and only once. Waxwing allows you to do just that.

## Requirements

* Swift 5
* iOS 8+

## Installation

Waxwing is available through [CocoaPods](http://cocoapods.org). To install add the following line to your Podfile:

    pod "Waxwing"
    
If you don't like CocoaPods, you can add the dependency via [Carthage](https://github.com/Carthage/Carthage) or include `Waxwing.swift` in your project.

## Usage

There are two ways to run your migrations, either with closures or through an `OperationQueue`:

``` swift
import Waxwing

…

let waxwing = Waxwing(bundle: .main, defaults: .standard)

waxwing.migrateToVersion("0.9") {
	firstMigrationCall()
	secondMigrationCall()
	…
}
```

or

``` swift
import Waxwing

…
let waxwing = Waxwing()

Waxwing.migrateToVersion("0.9", [FirstMigrationClass(), SecondMigrationClass()])
```

Note that closure based migrations are run from the thread they are created on. Anything that has to run on the main thread, such as notifying your users of changes introduced with this version, needs to explictly call the method on the main thread:

``` swift
import Waxwing

DispatchQueue.global().async {
	let waxwing = Waxwing(bundle: .main, defaults: .standard)
	waxwing.migrateToVersion("0.9") {
		DispatchQueue.main.async {
			// Some alert that we're done updating / what's new in this version of the app
		}
	}
}
```

The `OperationQueue` based migrations are always run from their own queue so the same caveat applies. Also note, that if any of the migrations in the queue depend on another one having run first, you explicitly need to add that dependency. `Operation` makes this trivial through the `addDependency()` method.

You can add as many migrations as you want. They will only ever be executed once.

## Progress

Waxwing has built in support for [Progress](https://developer.apple.com/documentation/foundation/progress). Since the number of actions that are run using the closure based method cannot be determined it just reports a total unit count of 1. If you're using operations, the unit count will match the number of migrations.

```swift
import Waxwing

func migrate() {
	let progress = Progress(totalUnitCount: 1)
	progress.becomeCurrent(withPendingUnitCount: 1)
	_ = progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
		// e.g. Update progress indicator, remember to do this on the main thread
	}
	
	waxwing.migrateToVersion("0.8", migrations: [migration1, migration2, migration3…])
}
```

For more information on how `Progress` works I recommend [this article](http://oleb.net/blog/2014/03/nsprogress/) by Ole Begemann.

## Author

Jan Gorman

## License

Waxwing is available under the MIT license. See the LICENSE file for more info.

