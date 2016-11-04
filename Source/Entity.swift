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

	private var unusedID = 0 as UInt64
	private var removeHandles = [:] as [Entity: [StoreID: RemoveHandle]]
	private var parents = [:] as [Entity: Entity]
	private var children = [:] as [Entity: Set<Entity>]

	public func create() -> Entity {
		let entity = Entity(id: unusedID)
		unusedID += 1
		return entity
	}

	public func create(boundTo parent: Entity) -> Entity {
		let entity = create()
		parents[entity] = parent
		var parentChildren = children[parent] ?? []
		parentChildren.insert(entity)
		children[parent] = parentChildren
		return entity
	}

	public func removeEntity(_ entity: Entity) {
		if let children = children.removeValue(forKey: entity) {
			for child in children {
				removeEntity(child)
			}
		}

		parents[entity] = nil
		removeComponents(for: entity)
	}

	func setRemoveHandle(entity: Entity, storeID: StoreID, handle: RemoveHandle?) {
		var handles = removeHandles[entity] ?? [:]
		handles[storeID] = handle
		removeHandles[entity] = handles
	}

	private func removeComponents(for entity: Entity) {
		if let handles = removeHandles.removeValue(forKey: entity) {
			for handle in handles.values {
				handle()
			}
		}
	}
}
