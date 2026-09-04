import CoreGraphics
import Testing
@testable import BillionCode

@Suite("ChapterGraphLayout")
struct ChapterGraphLayoutTests {
    @Test("Layout is deterministic when chapter input order changes")
    func deterministicOrder() {
        let atlas = GraphAtlasFixture.editorial
        let chapter = atlas.leadChapter
        let reordered = GraphChapter(
            id: chapter.id,
            title: chapter.title,
            heroNodeID: chapter.heroNodeID,
            memberIDs: chapter.memberIDs.reversed(),
            routes: chapter.routes.reversed(),
            accentIndex: chapter.accentIndex
        )
        let layout = ChapterGraphLayout()

        #expect(
            layout.layout(chapter: chapter, atlas: atlas, layoutVersion: 1)
                == layout.layout(chapter: reordered, atlas: atlas, layoutVersion: 1)
        )
    }

    @Test("Hero is fixed and six-person composition has no visual collisions")
    func collisionFreeComposition() {
        let atlas = GraphAtlasFixture.editorial
        let chapter = atlas.leadChapter
        let positions = ChapterGraphLayout().layout(
            chapter: chapter,
            atlas: atlas,
            layoutVersion: atlas.layoutVersion
        )

        #expect(positions[chapter.heroNodeID] == NormalizedGraphPoint(x: 0.5, y: 0.43))
        for size in [CGSize(width: 320, height: 520), CGSize(width: 393, height: 600)] {
            let frames = chapter.memberIDs.compactMap { id -> CGRect? in
                guard let point = positions[id] else { return nil }
                let nodeSize = id == chapter.heroNodeID
                    ? CGSize(width: 104, height: 128)
                    : CGSize(width: 96, height: 92)
                return CGRect(
                    x: point.x * size.width - nodeSize.width / 2,
                    y: point.y * size.height - nodeSize.height / 2,
                    width: nodeSize.width,
                    height: nodeSize.height
                )
            }
            for leftIndex in frames.indices {
                for rightIndex in frames.indices where leftIndex < rightIndex {
                    #expect(!frames[leftIndex].intersects(frames[rightIndex]))
                }
            }
        }
    }
}
