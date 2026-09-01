enum ContentValidationError: Error, Equatable {
    case unsupportedSchema(Int)
    case duplicateEntityID(String)
    case duplicateLayoutPosition(String)
    case danglingVisibleEntity(String)
    case missingLayoutPosition(String)
    case missingFallbackEdition(String)
    case duplicateID(String)
    case danglingReference(String)
    case missingRelationshipClaim(String)
    case missingClaimSource(String)
    case invalidClaimSubject(String)
    case disputedRelationshipWithoutOpposingClaims(String)
}
