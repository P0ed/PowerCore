import Fx

typealias StoreID = UInt16

public final class Store<C> {

	public unowned var entityManager: EntityManager

	private let id: StoreID
	private var entities: [Entity] = []
	private var components: [C] = []
	private var indexes: [MutableBox<Int>] = []
	private var map: [Entity: Int] = [:]

	public let newComponents: Signal<Int>
	private let newComponentsPipe: (Int) -> ()

	public let removedComponents: Signal<(Entity, C)>
	private let removedComponentsPipe: ((Entity, C)) -> ()

	init(id: StoreID, entityManager: EntityManager) {
		self.id = id
		self.entityManager = entityManager

		(newComponents, newComponentsPipe) = Signal.pipe()
		(removedComponents, removedComponentsPipe) = Signal.pipe()
	}

	public func sharedIndexAt(_ index: Int) -> ComponentIdx<C> {
		return ComponentIdx(box: indexes[index].box)
	}

	public func indexOf(_ entity: Entity) -> Int? {
		return entityManager.isAlive(entity) ? map[entity] : nil
	}

	public func entityAt(_ index: Int) -> Entity {
		return entities[index]
	}

	public subscript(index: Int) -> C {
		get {
			return components[index]
		}
		set(component) {
			components[index] = component
		}
	}

	public subscript(index: ComponentIdx<C>) -> C {
		get { return self[index.box.value] }
		set { self[index.box.value] = newValue }
	}

	public func weakRefAt(_ index: Int) -> WeakRef<C> {
		return WeakRef(store: self, entity: entities[index], index: sharedIndexAt(index))
	}

	public func refAt(_ index: Int) -> Ref<C> {
		return Ref(store: self, entity: entities[index], index: index)
	}

	@discardableResult
	public func add(component: C, to entity: Entity) -> Int {
		let index = components.count
		let sharedIndex = MutableBox(index)

		entities.append(entity)
		components.append(component)
		indexes.append(sharedIndex)
		map[entity] = index

		entityManager.setRemoveHandle(entity: entity, storeID: id) { [weak self] in
			self?.removeAt(sharedIndex.value)
		}

		newComponentsPipe(index)

		return index
	}

	func set(component: C, to entity: Entity) {
		guard entityManager.isAlive(entity) else { return }

		if let index = map[entity] {
			self[index] = component
		} else {
			add(component: component, to: entity)
		}
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

		entityManager.setRemoveHandle(entity: entity, storeID: id, handle: nil)

		removedComponentsPipe((entity, component))
	}

	public var indices: CountableRange<Int> {
		return 0..<entities.count
	}
}

extension Store: Sequence {
	public typealias Iterator = Array<C>.Iterator

	public func makeIterator() -> Store.Iterator {
		return components.makeIterator()
	}
}

public extension Store {

	public func removeComponents(where f: (Entity, C) -> Bool) {
		var index = 0
		while index < components.count {
			if f(entities[index], components[index]) {
				removeAt(index)
			} else {
				index += 1
			}
		}
	}

	public func removeEntities(where f: (Entity, C) -> Bool) {
		var index = 0
		while index < components.count {
			let entity = entities[index]
			if f(entity, components[index]) {
				removeAt(index)
				entityManager.removeEntity(entity)
			} else {
				index += 1
			}
		}
	}
}
