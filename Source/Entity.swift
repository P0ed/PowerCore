public struct Entity {
	let id: UInt64

	var generation: UInt32 {
		return UInt32(id >> 32)
	}
	var index: UInt32 {
		return UInt32(id & Entity.mask)
	}

	init(generation: UInt32, index: UInt32) {
		id = UInt64(generation) << 32 | UInt64(index)
	}

	var next: UInt32 {
		return generation < .max ? generation + 1 : 0
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

	private var generation: [UInt32] = []
	private var freeIndices: [UInt32] = []
	private var removeHandles: [Entity: [StoreID: RemoveHandle]] = [:]

	public func create() -> Entity {
		if freeIndices.count > 0 {
			let index = freeIndices.removeLast()
			return Entity(generation: generation[Int(index)], index: index)
		} else {
			let entity = Entity(generation: 0, index: UInt32(generation.count))
			generation.append(entity.generation)
			return entity
		}
	}

	public func removeEntity(_ entity: Entity) {

		if let handles = removeHandles.removeValue(forKey: entity) {
			for handle in handles.values {
				handle()
			}
		}

		generation[Int(entity.index)] = entity.next
		freeIndices.append(entity.index)
	}

	func isAlive(_ entity: Entity) -> Bool {
		return generation[Int(entity.index)] == entity.generation
	}

	func setRemoveHandle(entity: Entity, storeID: StoreID, handle: RemoveHandle?) {
		var handles = removeHandles[entity] ?? [:]
		handles[storeID] = handle
		removeHandles[entity] = handles
	}
}
