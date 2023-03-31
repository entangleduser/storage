@_exported import Transactions
protocol TransactionalContent: DynamicContent {}
extension Content {
 var isTransactional: Bool { self is any TransactionalContent }
}

// TODO: Extend ``Folder`` to be transactional
/// A content structure that updates when it recieves a transaction
/// or a source to target with a provable data structure that's tagged
/// according to the transaction so the contents are readable and writable
/// by the variadic or dynamic contraints of the structure
/// The variable can be sent and recieved through an alias in combination
/// with a transactional token
/// An alias can expand the transactional token to allow a specific type to be
/// read and written if positioned on the structure
/*
 struct ContentTransaction<A: Transactional>: TransactionalContent
 where A: LosslessStringConvertible {
  unowned var _reflection: Reflection?
  var _traits: Storage.Traits?
  var _attributes: Storage.Attributes?
  let result: (A) -> AnyContent
  init(@Storage.Contents _ result: @escaping (A) -> AnyContent) {
   self.result = result
  }
 }
 */
