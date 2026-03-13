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
        let context = persistentContainer.viewContext

        let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { toDomain($0) }
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
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { backgroundContext in
                do {
                    // Set merge policy to handle conflicts
                    backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    backgroundContext.undoManager = nil

                    // Check if entity already exists
                    let request = NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
                    request.predicate = NSPredicate(format: "id == %@", polynomial.id as CVarArg)
                    request.fetchLimit = 1

                    let existingEntities = try? backgroundContext.fetch(request)
                    let entity = existingEntities?.first ?? PolynomialEntity(context: backgroundContext)

                    // Set values
                    entity.id = polynomial.id
                    entity.originalExpression = polynomial.originalExpression
                    entity.simplifiedExpression = polynomial.simplifiedExpression
                    entity.derivative = polynomial.derivative
                    entity.valueAt1Optional = polynomial.valueAt1
                    entity.valueAt2Optional = polynomial.valueAt2
                    entity.imagePath = polynomial.imagePath
                    entity.createdAt = polynomial.createdAt

                    try backgroundContext.save()
                    continuation.resume()
                } catch {
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
            id: entity.id,
            originalExpression: entity.originalExpression,
            simplifiedExpression: entity.simplifiedExpression,
            derivative: entity.derivative,
            valueAt1: entity.valueAt1Optional,
            valueAt2: entity.valueAt2Optional,
            imagePath: entity.imagePath,
            createdAt: entity.createdAt
        )
    }
}
