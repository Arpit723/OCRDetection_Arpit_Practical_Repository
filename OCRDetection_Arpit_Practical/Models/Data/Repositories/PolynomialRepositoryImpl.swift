//
//  PolynomialRepositoryImpl.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//

import Foundation
import CoreData

/// Core Data implementation of PolynomialRepository.
final class PolynomialRepositoryImpl: PolynomialRepository {

    // MARK: - Properties

    private let persistentContainer: NSPersistentContainer
    private let imageFileManager: ImageFileManager

    // MARK: - Init

    init(persistentContainer: NSPersistentContainer, imageFileManager: ImageFileManager = .shared) {
        self.persistentContainer = persistentContainer
        self.imageFileManager = imageFileManager
    }

    // MARK: - PolynomialRepository

    func fetchAll() async throws -> [Polynomial] {
        print("💾 [DEBUG] Repository: fetchAll called")
        let context = persistentContainer.viewContext

        print("  📊 [DEBUG] Repository: Creating fetch request for PolynomialEntity")
        let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        print("  🔍 [DEBUG] Repository: Executing fetch on main context (registered objects: \(context.registeredObjects.count))")
        let entities = try context.fetch(request)
        print("  ✅ [DEBUG] Repository: Fetched \(entities.count) entities from Core Data")

        let domainModels = entities.map { toDomain($0) }
        print("  ✅ [DEBUG] Repository: Converted to \(domainModels.count) domain models")

        return domainModels
    }

    func fetchById(_ id: UUID) async throws -> Polynomial? {
        let context = persistentContainer.viewContext

        let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entity = try context.fetch(request).first
        return entity.map { toDomain($0) }
    }

    func save(_ polynomial: Polynomial) async throws {
        print("💾 [DEBUG] Repository: save called for polynomial '\(polynomial.originalExpression)'")
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { backgroundContext in
                do {
                    print("  🔧 [DEBUG] Repository: Setting up background context")
                    // Set merge policy to handle conflicts
                    backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    backgroundContext.undoManager = nil

                    // Check if entity already exists
                    print("  🔍 [DEBUG] Repository: Checking for existing entity with id: \(polynomial.id)")
                    let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
                    request.predicate = NSPredicate(format: "id == %@", polynomial.id as CVarArg)
                    request.fetchLimit = 1

                    let existingEntities = try backgroundContext.fetch(request)
                    let entity = existingEntities.first ?? PolynomialEntity(context: backgroundContext)

                    if existingEntities.first != nil {
                        print("  🔄 [DEBUG] Repository: Updating existing entity")
                    } else {
                        print("  ➕ [DEBUG] Repository: Creating new entity")
                    }

                    // Set values
                    print("  📝 [DEBUG] Repository: Setting entity properties")
                    entity.id = polynomial.id
                    entity.originalExpression = polynomial.originalExpression
                    entity.simplifiedExpression = polynomial.simplifiedExpression
                    entity.derivative = polynomial.derivative
                    entity.valueAt1 = polynomial.valueAt1.map { NSDecimalNumber(value: $0) }
                    entity.valueAt2 = polynomial.valueAt2.map { NSDecimalNumber(value: $0) }
                    entity.imagePath = polynomial.imagePath
                    entity.createdAt = polynomial.createdAt

                    print("  💾 [DEBUG] Repository: Saving background context...")
                    try backgroundContext.save()
                    print("  ✅ [DEBUG] Repository: Background context saved successfully")

                    // Resume continuation IMMEDIATELY after save
                    // Don't dispatch to main queue - that causes continuation leak
                    continuation.resume()

                    // Verify the save was merged to main context (async, non-blocking)
                    DispatchQueue.main.async {
                        let mainContext = self.persistentContainer.viewContext
                        print("  🔍 [DEBUG] Repository: Main context now has \(mainContext.registeredObjects.count) registered objects")
                        // Refresh main context to ensure we see the changes
                        mainContext.refreshAllObjects()
                    }
                } catch {
                    print("  ❌ [DEBUG] Repository: Save failed with error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func delete(id: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                // First, get the entity to find the image path
                let context = persistentContainer.viewContext
                let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1

                guard let entity = try context.fetch(request).first else {
                    continuation.resume()
                    return
                }

                // Delete image file if exists
                if let imagePath = entity.imagePath {
                    try? self.imageFileManager.deleteImage(at: imagePath)
                }

                // Delete entity
                context.delete(entity)
                try context.save()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteAll() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let context = persistentContainer.viewContext
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PolynomialEntity")

                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                deleteRequest.resultType = .resultTypeCount

                try context.execute(deleteRequest)
                try context.save()

                // Clean up all image files
                try? self.imageFileManager.deleteAllImages()

                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Mapping

    private func toDomain(_ entity: PolynomialEntity) -> Polynomial {
        Polynomial(
            id: entity.id ?? UUID(),
            originalExpression: entity.originalExpression!,
            simplifiedExpression: entity.simplifiedExpression,
            derivative: entity.derivative,
            valueAt1: entity.valueAt1?.doubleValue,
            valueAt2: entity.valueAt2?.doubleValue,
            imagePath: entity.imagePath,
            createdAt: entity.createdAt ?? Date()
        )
    }
}
