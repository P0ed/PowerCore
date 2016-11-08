public struct Entity {
	let id: UInt64

	var generation: Int {
		return Int(id >> 32 & Entity.mask)
	}
	var index: Int {
		return Int(id & Entity.mask)
	}

	var next: Entity {
		let nextGen = generation < Int(UInt32.max) ? generation + 1 : 0
		return Entity(id: UInt64(nextGen << 32 | index))
	}

	static let mask: UInt64 = (1 << 32) - 1
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

	private var entities: [Entity] = []
	private var removeHandles: [Entity: [StoreID: RemoveHandle]] = [:]
	private var freeList: [Entity] = []

	public func create() -> Entity {
		if freeList.count > 0 {
			let entity = freeList.removeLast().next
			entities[entity.index] = entity
			return entity
		}
		else {
			let entity = Entity(id: UInt64(entities.count))
			entities.append(entity)
			return entity
		}
	}

	public func removeEntity(_ entity: Entity) {

		if let handles = removeHandles.removeValue(forKey: entity) {
			for handle in handles.values {
				handle()
			}
		}

		freeList.append(entity)
	}

	func isAlive(_ entity: Entity) -> Bool {
		return entities[entity.index] == entity
	}

	func setRemoveHandle(entity: Entity, storeID: StoreID, handle: RemoveHandle?) {
		var handles = removeHandles[entity] ?? [:]
		handles[storeID] = handle
		removeHandles[entity] = handles
	}
}
