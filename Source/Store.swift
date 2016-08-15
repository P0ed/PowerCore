import Fx

typealias StoreID = UInt16

public final class Store<Component> {

	private weak var entityManager: EntityManager?

	private let id: StoreID
	private var entities: ContiguousArray<Entity> = []
	private var components: ContiguousArray<Component> = []
	private var indexes: ContiguousArray<MutableBox<Int>> = []
	private var map: [Entity: Int] = [:]

	public let newComponents: Stream<Int>
	private let newComponentsPipe: Int -> ()

	public let removedComponents: Stream<(Entity, Component)>
	private let removedComponentsPipe: (Entity, Component) -> ()

	init(id: StoreID, entityManager: EntityManager) {
		self.id = id
		self.entityManager = entityManager

		(newComponents, newComponentsPipe) = Stream.pipe()
		(removedComponents, removedComponentsPipe) = Stream.pipe()
	}

	public func sharedIndexAt(idx: Int) -> Box<Int> {
		return indexes[idx].box
	}

	public func indexOf(entity: Entity) -> Int? {
		return map[entity]
	}

	public func entityAt(idx: Int) -> Entity {
		return entities[idx]
	}

	public subscript(idx: Int) -> Component {
		get {
			return components[idx]
		}
		set(component) {
			components[idx] = component
		}
	}

	public func add(component: Component, to entity: Entity) -> Int {
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

		return idx
	}

	public func removeAt(idx: Int) {
		let entity = entities[idx]
		let component = components[idx]
		let lastInt = entities.endIndex.predecessor()
		let lastEntity = entities[lastInt]

		entities[idx] = entities[lastInt]
		entities.removeLast()

		components[idx] = components[lastInt]
		components.removeLast()

		let sharedInt = indexes[lastInt]
		sharedInt.value = idx
		indexes[idx] = sharedInt
		indexes.removeLast()

		map[lastEntity] = idx
		map.removeValueForKey(entity)

		entityManager?.setRemoveHandle(entity, storeID: id, handle: nil)

		removedComponentsPipe(entity, component)
	}
}
