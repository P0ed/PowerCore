public struct Entity {
	let id: UInt64
}

extension Entity: Hashable {

	public var hashValue: Int {
		return id.hashValue
	}

	public static func ==(lhs: Entity, rhs: Entity) -> Bool {
		return lhs.id == rhs.id
	}
}

public final class EntityManager {
	typealias RemoveHandle = () -> ()

	private var unusedID: UInt64 = 0
	private var removeHandles: [Entity: [StoreID: RemoveHandle]] = [:]

	public func create() -> Entity {
		let entity = Entity(id: unusedID)
		unusedID += 1
		return entity
	}

	func setRemoveHandle(entity: Entity, storeID: StoreID, handle: RemoveHandle?) {
		var handles = removeHandles[entity] ?? [:]
		handles[storeID] = handle
		removeHandles[entity] = handles
	}
}
