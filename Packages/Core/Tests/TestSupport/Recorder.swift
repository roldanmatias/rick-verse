public actor Recorder<Value: Sendable> {
    public private(set) var values: [Value] = []

    public init() {}

    public func append(_ value: Value) {
        values.append(value)
    }
}
