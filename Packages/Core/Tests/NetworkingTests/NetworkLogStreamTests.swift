import Foundation
import Networking
import Testing

struct NetworkLogStreamTests {
    private func event(_ status: Int) -> NetworkEvent {
        NetworkEvent(source: .rest, label: "GET /x", status: status, duration: .milliseconds(10), bytes: 1)
    }

    @Test("updates() yields the current snapshot first, then one after each change")
    func streamsSnapshots() async {
        let log = NetworkLog()
        await log.record(event(200))

        var iterator = log.updates().makeAsyncIterator()
        #expect(await iterator.next()?.map(\.status) == [200])

        await log.record(event(201))
        #expect(await iterator.next()?.map(\.status) == [200, 201])

        await log.clear()
        #expect(await iterator.next()?.isEmpty == true)
    }

    @Test func multipleSubscribersEachGetUpdates() async {
        let log = NetworkLog()
        var first = log.updates().makeAsyncIterator()
        var second = log.updates().makeAsyncIterator()
        _ = await first.next()
        _ = await second.next()

        await log.record(event(500))

        #expect(await first.next()?.first?.status == 500)
        #expect(await second.next()?.first?.status == 500)
    }
}
