//
//  AppDelegate.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Window Property (AppDelegate-only pattern)

    var window: UIWindow?

    // MARK: - Application Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Setup window programmatically (no SceneDelegate)
        setupWindow()

        // Test Core Data initialization
        print("🧪 Testing Core Data initialization...")
        let container = persistentContainer

        // Verify store loaded
        print("   Store coordinator: \(container.persistentStoreCoordinator)")
        print("   Persistent stores: \(container.persistentStoreCoordinator.persistentStores)")
        print("   Managed object model: \(container.managedObjectModel)")

        // Test fetch request
        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PolynomialEntity")
        do {
            let count = try context.count(for: request)
            print("   ✅ Core Data working! Found \(count) existing polynomials")
        } catch {
            print("   ❌ Core Data fetch failed: \(error)")
        }

        // Setup notification-based context merge for background saves
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let context = self?.persistentContainer.viewContext else { return }
            context.mergeChanges(fromContextDidSave: notification)
        }

        return true
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let window = UIWindow(frame: UIScreen.main.bounds)

        // Initialize from Main.storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateInitialViewController()

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        self.window = window
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save Core Data changes when entering background
        saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Save changes before termination
        saveContext()
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        // Model name must match the .xcdatamodeld directory name exactly
        let container = NSPersistentContainer(name: "OCRDetection_Arpit_Practical")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Core Data store loading failed: \(error)")
                print("   Store URL: \(storeDescription.url?.path ?? "unknown")")
                print("   Store type: \(storeDescription.type)")
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        })

        // Enable automatic merge policy for better concurrency
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    // MARK: - Core Data Saving Support

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved Core Data save error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
