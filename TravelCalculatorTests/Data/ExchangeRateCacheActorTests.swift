import Testing
import Foundation
@testable import TravelCalculator

struct ExchangeRateCacheActorTests {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    private func makeResponse(fetchedAt: Date = .now, searchDate: String = "2026-04-11") -> ExchangeRateResponse {
        ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1350)],
            fetchedAt: fetchedAt,
            searchDate: searchDate
        )
    }

    // MARK: - save & load

    @Test func saveAndLoad_roundTrips() async throws {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        let response = makeResponse()

        try await actor.save(response)
        let loaded = await actor.load()

        #expect(loaded?.searchDate == response.searchDate)
        #expect(loaded?.rates.first?.rate == response.rates.first?.rate)
    }

    @Test func load_whenFileDoesNotExist_returnsNil() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)

        let loaded = await actor.load()

        #expect(loaded == nil)
    }

    // MARK: - isValid

    @Test func isValid_within24h_returnsTrue() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        let response = makeResponse(fetchedAt: Date(timeIntervalSinceNow: -3600)) // 1시간 전

        let valid = await actor.isValid(response)

        #expect(valid == true)
    }

    @Test func isValid_over24h_returnsFalse() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        let response = makeResponse(fetchedAt: Date(timeIntervalSinceNow: -86401)) // 24시간 1초 전

        let valid = await actor.isValid(response)

        #expect(valid == false)
    }

    // MARK: - delete

    @Test func deleteCache_removesFile() async throws {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        try await actor.save(makeResponse())

        try await actor.delete()

        let loaded = await actor.load()
        #expect(loaded == nil)
    }

    // MARK: - corrupt JSON

    @Test func load_withCorruptJSON_returnsNilAndDeletesFile() async throws {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        try "not valid json".write(to: url, atomically: true, encoding: .utf8)

        let loaded = await actor.load()

        #expect(loaded == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
}
