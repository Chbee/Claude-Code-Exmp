import Testing
import Foundation
@testable import TravelCalculator

struct ExchangeRateCacheActorTests {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    private func makeResponse(
        fetchedAt: Date = .now,
        searchDate: String = "20260410",
        validUntil: Date = .distantFuture
    ) -> ExchangeRateResponse {
        ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1350)],
            fetchedAt: fetchedAt,
            searchDate: searchDate,
            validUntil: validUntil
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
        #expect(loaded?.validUntil == response.validUntil)
    }

    @Test func load_whenFileDoesNotExist_returnsNil() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)

        let loaded = await actor.load()

        #expect(loaded == nil)
    }

    // MARK: - isValid (Date.now < validUntil)

    @Test func isValid_whenNowBeforeValidUntil_returnsTrue() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        let response = makeResponse(validUntil: Date(timeIntervalSinceNow: 3600))

        let valid = await actor.isValid(response)

        #expect(valid == true)
    }

    @Test func isValid_whenNowAfterValidUntil_returnsFalse() async {
        let url = makeTempFileURL()
        let actor = ExchangeRateCacheActor(fileURL: url)
        let response = makeResponse(validUntil: Date(timeIntervalSinceNow: -3600))

        let valid = await actor.isValid(response)

        #expect(valid == false)
    }

    // MARK: - backward compat (old cache without validUntil)

    @Test func load_legacyCacheWithoutValidUntil_decodesWithDistantPast() async throws {
        let url = makeTempFileURL()
        let legacyJSON = """
        {"rates":[{"currency":"USD","currencyName":"미국 달러","rate":1350}],"fetchedAt":\(Date.now.timeIntervalSinceReferenceDate),"searchDate":"20260410"}
        """
        try legacyJSON.write(to: url, atomically: true, encoding: .utf8)
        let actor = ExchangeRateCacheActor(fileURL: url)

        let loaded = await actor.load()

        #expect(loaded != nil)
        #expect(loaded?.validUntil == .distantPast)
        let valid = await actor.isValid(loaded!)
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
