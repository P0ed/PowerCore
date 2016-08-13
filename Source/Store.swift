import Fx

typealias StoreID = UInt16

public final class Store<Component> {
	public typealias Index = Int

	private weak var entityManager: EntityManager?

	private let id: StoreID
	private var entities: ContiguousArray<Entity> = []
	private var components: ContiguousArray<Component> = []
	private var indexes: ContiguousArray<MutableBox<Index>> = []
	private var map: [Entity: Index] = [:]

	public let newComponents: Stream<Index>
	private let newComponentsPipe: Index -> ()

	public let removedComponents: Stream<(Entity, Component)>
	private let removedComponentsPipe: (Entity, Component) -> ()

	init(id: StoreID, entityManager: EntityManager) {
		self.id = id
		self.entityManager = entityManager

		(newComponents, newComponentsPipe) = Stream.pipe()
		(removedComponents, removedComponentsPipe) = Stream.pipe()
	}

	public func sharedIndexAt(idx: Index) -> Box<Index> {
		return indexes[idx].box
	}

	public func indexOf(entity: Entity) -> Index? {
		return map[entity]
	}

	public func entityAt(idx: Index) -> Entity {
		return entities[idx]
	}

	public subscript(idx: Index) -> Component {
		get {
			return components[idx]
		}
		set(component) {
			components[idx] = component
		}
	}

	public func add(component: Component, to entity: Entity) -> Box<Index> {
		let idx = components.count
		let sharedIdx = MutableBox(idx)

		entities.append(entity)
		components.append(component)
		indexes.append(sharedIdx)
		map[entity] = idx

		entityManager?.setRemoveHandle(entity, storeID: id) { [weak self] in
			self?.removeAt(sharedIdx.value)
		}

		newComponentsPipe(idx)

		return sharedIdx.box
	}

	public func removeAt(idx: Index) {
		let entity = entities[idx]
		let component = components[idx]
		let lastIndex = entities.endIndex.predecessor()
		let lastEntity = entities[lastIndex]

		entities[idx] = entities[lastIndex]
		entities.removeLast()

		components[idx] = components[lastIndex]
		components.removeLast()

		let sharedIndex = indexes[lastIndex]
		sharedIndex.value = idx
		indexes[idx] = sharedIndex
		indexes.removeLast()

		map[lastEntity] = idx
		map.removeValueForKey(entity)

		entityManager?.setRemoveHandle(entity, storeID: id, handle: nil)

		removedComponentsPipe(entity, component)
	}
}
