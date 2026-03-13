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
        let container = NSPersistentContainer(name: "OCRDetection_Arpit_Practical")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        })
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
