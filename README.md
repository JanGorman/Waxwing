[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Waxwing

iOS version migrations in Swift. When mangling data or performing any other kind of updates you want to ensure that all relevant migrations are run in order and only once. Waxwing allows you to just that.

## Requirements

* iOS 8+

## Installation

Waxwing is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "Waxwing"
    
If you don't like Cocoapods just include `Waxwing.swift` in your project.

## Usage

There are two ways to run your migrations, either with closures or through an `NSOperationQueue`:

``` swift
import Waxwing

…

Waxwing.migrateToVersion("0.9") {
	firstMigrationCall()
	secondMigrationCall()
	…
}
```

or

``` swift
import Waxwing

…

Waxwing.migrateToVersion("0.9", [FirstMigrationClass(), SecondMigrationClass()])
```

Note, that closure based migrations are run from the thread they are created on so any thing that has to run on the main thread, such as notifying your users of changes introduced with this version or something similar, needs to explictly call the method on the main thread:

``` swift
import Waxwing

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
	Waxwing.migrateToVersion("0.9") {
		someMigrationFunction()
		
		dispatch_async(dispatch_get_main_queue()) {
			// Some alert that we're done updating / what's new in this version of the app
		}
	}
}
```

The `NSOperationQueue` based migrations are always run from their own queue so the same caveat applies. Also note, that if any of the migrations in the queue depend on another one having run first, you explicitly need to add that dependency. `NSOperation` of course makes this trivial through the `addDependency()` method.

You can add as many migrations as you want. They will always be executed once which makes reasoning about the state of your application a lot easier.

## Author

Jan Gorman, gorman.jan@gmail.com

## License

Waxwing is available under the MIT license. See the LICENSE file for more info.

