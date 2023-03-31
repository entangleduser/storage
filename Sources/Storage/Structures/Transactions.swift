@_exported import Transactions
/// A transaction used to modify the structure of `Content`
/// usually in a context where there are senders and recievers with unique
/// tags or ids
protocol FileTransaction: Transactional
where Source: LosslessStringConvertible, Target: LosslessStringConvertible {}
