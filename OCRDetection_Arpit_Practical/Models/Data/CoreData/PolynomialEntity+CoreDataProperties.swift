//
//  PolynomialEntity+CoreDataProperties.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//


import Foundation
import CoreData

extension PolynomialEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PolynomialEntity> {
        return NSFetchRequest<PolynomialEntity>(entityName: "PolynomialEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var originalExpression: String
    @NSManaged public var simplifiedExpression: String?
    @NSManaged public var derivative: String?
    @NSManaged public var valueAt1: Double
    @NSManaged public var valueAt2: Double
    @NSManaged public var imagePath: String?
    @NSManaged public var createdAt: Date
    @NSManaged private var primitiveValueAt1: NSNumber?
    @NSManaged private var primitiveValueAt2: NSNumber?

}

// MARK: - Computed Properties for Optional Handling
extension PolynomialEntity {

    // Optional access to valueAt1 - returns nil if explicitly set as nil
    var valueAt1Optional: Double? {
        get {
            // Check if the primitive value is explicitly nil
            return primitiveValueAt1?.doubleValue
        }
        set {
            primitiveValueAt1 = newValue.map { NSNumber(value: $0) }
        }
    }

    // Optional access to valueAt2 - returns nil if explicitly set as nil
    var valueAt2Optional: Double? {
        get {
            return primitiveValueAt2?.doubleValue
        }
        set {
            primitiveValueAt2 = newValue.map { NSNumber(value: $0) }
        }
    }

    /// Check if simplified expression exists
    var hasSimplifiedExpression: Bool {
        return simplifiedExpression != nil && !simplifiedExpression!.isEmpty
    }

    /// Check if derivative exists
    var hasDerivative: Bool {
        return derivative != nil && !derivative!.isEmpty
    }

    /// Check if image path exists
    var hasImage: Bool {
        return imagePath != nil && !imagePath!.isEmpty
    }

    /// Check if valueAt1 has an explicitly set value
    var hasValueAt1: Bool {
        return primitiveValueAt1 != nil
    }

    /// Check if valueAt2 has an explicitly set value
    var hasValueAt2: Bool {
        return primitiveValueAt2 != nil
    }
}

extension PolynomialEntity : Identifiable {
}
