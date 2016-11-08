import Fx

public struct Component<A> {
	let store: Store<A>
	let entity: Entity
	let index: Box<Int>

	public var value: A? {
		get {
			if store.entityManager.isAlive(entity) {
				return store[index.value]
			} else {
				return nil
			}
		}
		nonmutating set {
			if let value = newValue, store.entityManager.isAlive(entity) {
				store[index.value] = value
			}
		}
	}
}
