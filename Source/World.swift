public final class World {

	private var unusedStoreID: StoreID = 0
	public let entityManager: EntityManager

	public init() {
		entityManager = EntityManager()
	}

	public func createStore<Component>() -> Store<Component> {
		let store = Store<Component>(id: unusedStoreID, entityManager: entityManager)
		unusedStoreID += 1
		return store
	}
}
