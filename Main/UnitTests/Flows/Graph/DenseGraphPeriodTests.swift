import Testing
@testable import BillionCode

@Suite("Dense graph periods")
struct DenseGraphPeriodTests {
    @Test("Single year intersects a range containing it")
    func singleYearOverlap() throws {
        let single = try #require(DenseGraphPeriod("1995"))
        let range = try #require(DenseGraphPeriod("1993–1995"))

        #expect(single.overlaps(range))
    }

    @Test("Separated ranges do not intersect")
    func noOverlap() throws {
        let earlier = try #require(DenseGraphPeriod("1995–1999"))
        let later = try #require(DenseGraphPeriod("2003–2005"))

        #expect(!earlier.overlaps(later))
    }

    @Test("Current periods overlap a later finite range")
    func ongoingOverlap() throws {
        let ongoing = try #require(DenseGraphPeriod("2008–н.в."))
        let finite = try #require(DenseGraphPeriod("2017–2019"))

        #expect(ongoing.overlaps(finite))
    }
}
