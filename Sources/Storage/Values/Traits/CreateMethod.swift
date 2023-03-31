/// The specific behavior when creating content
/// that can be managed using a few methods
/// `automatic` will automatically create content if a
/// default value is provided
/// `assigned` will create content when assigned a value
enum CreateMethod: UInt, Infallible, @unchecked Sendable {
 static var defaultValue: Self { .automatic }
 case automatic // , assigned
}
