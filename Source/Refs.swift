import Fx

public struct WeakRef<A> {
	unowned let store: Store<A>
	public let entity: Entity
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
			if store.entityManager.isAlive(entity) {
				if let value = newValue {
					store[index.value] = value
				} else {
					store.removeAt(index.value)
				}
			}
		}
	}

	var ref: Ref<A>? {
		if store.entityManager.isAlive(entity) {
			return store.refAt(index.value)
		}
		return nil
	}
}

public struct Ref<A> {
	unowned let store: Store<A>
	public let entity: Entity
	let index: Int

	public var value: A {
		get {
			return store[index]
		}
		nonmutating set {
			return store[index] = newValue
		}
	}

	func delete() {
		store.removeAt(index)
	}

	var weakRef: WeakRef<A> {
		return store.weakRefAt(index)
	}
}
