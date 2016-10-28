import Fx

typealias StoreID = UInt16

public final class Store<Component> {

	fileprivate weak var entityManager: EntityManager!

	private let id: StoreID
	fileprivate var entities: ContiguousArray<Entity> = []
	fileprivate var components: ContiguousArray<Component> = []
	private var indexes: ContiguousArray<MutableBox<Int>> = []
	private var map: [Entity: Int] = [:]

	public let newComponents: Signal<Int>
	private let newComponentsPipe: (Int) -> ()

	public let removedComponents: Signal<(Entity, Component)>
	private let removedComponentsPipe: (Entity, Component) -> ()

	init(id: StoreID, entityManager: EntityManager) {
		self.id = id
		self.entityManager = entityManager

		(newComponents, newComponentsPipe) = Signal.pipe()
		(removedComponents, removedComponentsPipe) = Signal.pipe()
	}

	public func sharedIndexAt(_ index: Int) -> Box<Int> {
		return indexes[index].box
	}

	public func indexOf(_ entity: Entity) -> Int? {
		return map[entity]
	}

	public func entityAt(_ index: Int) -> Entity {
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

	@discardableResult
	public func add(component: Component, to entity: Entity) -> Int {
		let index = components.count
		let sharedIndex = MutableBox(index)

		entities.append(entity)
		components.append(component)
		indexes.append(sharedIndex)
		map[entity] = index

		entityManager?.setRemoveHandle(entity: entity, storeID: id) { [weak self] in
			self?.removeAt(sharedIndex.value)
		}

		newComponentsPipe(index)

		return index
	}

	public func removeAt(_ index: Int) {
		let entity = entities[index]
		let component = components[index]
		let lastInt = entities.endIndex - 1
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
		map[entity] = nil

		entityManager?.setRemoveHandle(entity: entity, storeID: id, handle: nil)

		removedComponentsPipe(entity, component)
	}

	public var indices: CountableRange<Int> {
		return 0..<entities.count
	}
}

extension Store: Sequence {
	public typealias Iterator = ContiguousArray<Component>.Iterator

	public func makeIterator() -> Store.Iterator {
		return components.makeIterator()
	}
}

public extension Store {

	public func removeComponents(where f: (Entity, Component) -> Bool) {
		var index = 0
		while index < components.count {
			if f(entities[index], components[index]) {
				removeAt(index)
			} else {
				index += 1
			}
		}
	}

	public func removeEntities(where f: (Entity, Component) -> Bool) {
		var index = 0
		while index < components.count {
			if f(entities[index], components[index]) {
				entityManager.removeEntity(entities[index])
			} else {
				index += 1
			}
		}
	}
}
