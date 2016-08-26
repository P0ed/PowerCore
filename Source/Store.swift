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

	public func sharedIndexAt(index: Int) -> Box<Int> {
		return indexes[index].box
	}

	public func indexOf(entity: Entity) -> Int? {
		return map[entity]
	}

	public func entityAt(index: Int) -> Entity {
		return entities[index]
	}

	public subscript(index: Int) -> Component {
		get {
			return components[index]
		}
		set(component) {
			components[index] = component
		}
	}

	public func add(component: Component, to entity: Entity) -> Int {
		let index = components.count
		let sharedIndex = MutableBox(index)

		entities.append(entity)
		components.append(component)
		indexes.append(sharedIndex)
		map[entity] = index

		entityManager?.setRemoveHandle(entity, storeID: id) { [weak self] in
			self?.removeAt(sharedIndex.value)
		}

		newComponentsPipe(index)

		return index
	}

	public func removeAt(index: Int) {
		let entity = entities[index]
		let component = components[index]
		let lastInt = entities.endIndex.predecessor()
		let lastEntity = entities[lastInt]

		entities[index] = entities[lastInt]
		entities.removeLast()

		components[index] = components[lastInt]
		components.removeLast()

		let sharedIndex = indexes[lastInt]
		sharedIndex.value = index
		indexes[index] = sharedIndex
		indexes.removeLast()

		map[lastEntity] = index
		map.removeValueForKey(entity)

		entityManager?.setRemoveHandle(entity, storeID: id, handle: nil)

		removedComponentsPipe(entity, component)
	}
}

extension Store: SequenceType {
	public typealias Generator = ContiguousArray<Component>.Generator

	public func generate() -> Store.Generator {
		return components.generate()
	}
}
