import SurveillanceCore

/// Pure presentation dress inferred from `WorldLayout` obstacle AABBs.
/// Collision remains simulation-owned; this builder never mutates Core state.
enum UrbanDressBuilder {
    /// World units from building pad edge to outer sidewalk edge (tune once).
    static let sidewalkWidth: Double = 14
    /// Minimum free-band height/width to treat as a full-span road corridor (tune once).
    static let minRoadWidth: Double = 28

    static func build(layout: WorldLayout, district: DistrictID) -> UrbanDress {
        _ = district // reserved for district-specific widths later
        let buildings: [UrbanBuildingDress] = layout.obstacles.map { o in
            let foot = UrbanRect(center: o.center, halfSize: o.halfSize)
            let outer = foot.expanded(by: sidewalkWidth).clamped(to: layout.bounds)
            return UrbanBuildingDress(obstacleID: o.id, footprint: foot, sidewalkOuter: outer)
        }

        // Sidewalk bands: one rect per building (outer); renderer draws as frame around pad.
        let sidewalks = buildings.map(\.sidewalkOuter)

        // Occupied = footprints only for road carve (sidewalks sit on road visually).
        let occupied = buildings.map(\.footprint)

        // Horizontal free strips: scan mid-Y free spans between obstacle projections.
        var roads: [UrbanRect] = []
        let bounds = layout.bounds
        // Full-width horizontal corridors at Y bands where continuous free height ≥ minRoadWidth,
        // and full-height vertical corridors at X bands with free width ≥ minRoadWidth.
        roads.append(contentsOf: horizontalRoadBands(bounds: bounds, occupied: occupied))
        roads.append(contentsOf: verticalRoadBands(bounds: bounds, occupied: occupied))

        // Intersections: overlaps of one H and one V road
        var intersections: [UrbanRect] = []
        let horiz = roads.filter { $0.width >= $0.height }
        let vert = roads.filter { $0.height > $0.width }
        for h in horiz {
            for v in vert where h.intersects(v) {
                intersections.append(UrbanRect(
                    minX: max(h.minX, v.minX), maxX: min(h.maxX, v.maxX),
                    minY: max(h.minY, v.minY), maxY: min(h.maxY, v.maxY)
                ))
            }
        }

        // Fallback: if no roads inferred, treat all free bounds as one road fill
        if roads.isEmpty {
            roads = [UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: bounds.minY, maxY: bounds.maxY
            )]
        }

        return UrbanDress(
            bounds: bounds,
            roads: roads,
            intersections: intersections,
            sidewalks: sidewalks,
            buildings: buildings,
            alleys: []
        )
    }

    // MARK: - Road band extraction (gap projection)

    /// Horizontal roads: project footprints onto Y, find free gaps ≥ minRoadWidth, emit full-X spans.
    static func horizontalRoadBands(bounds: WorldBounds, occupied: [UrbanRect]) -> [UrbanRect] {
        let intervals = occupied.map { ($0.minY, $0.maxY) }
        let gaps = freeGaps(
            lower: bounds.minY,
            upper: bounds.maxY,
            blocked: intervals,
            minWidth: minRoadWidth
        )
        return gaps.map { gap in
            UrbanRect(minX: bounds.minX, maxX: bounds.maxX, minY: gap.lower, maxY: gap.upper)
        }
    }

    /// Vertical roads: project footprints onto X, find free gaps ≥ minRoadWidth, emit full-Y spans.
    static func verticalRoadBands(bounds: WorldBounds, occupied: [UrbanRect]) -> [UrbanRect] {
        let intervals = occupied.map { ($0.minX, $0.maxX) }
        let gaps = freeGaps(
            lower: bounds.minX,
            upper: bounds.maxX,
            blocked: intervals,
            minWidth: minRoadWidth
        )
        return gaps.map { gap in
            UrbanRect(minX: gap.lower, maxX: gap.upper, minY: bounds.minY, maxY: bounds.maxY)
        }
    }

    /// Sort and merge blocked 1D intervals, then emit free gaps within [lower, upper] that are ≥ minWidth.
    private static func freeGaps(
        lower: Double,
        upper: Double,
        blocked: [(Double, Double)],
        minWidth: Double
    ) -> [(lower: Double, upper: Double)] {
        guard upper > lower else { return [] }

        let sorted = blocked
            .map { (min($0.0, $0.1), max($0.0, $0.1)) }
            .filter { $0.1 > lower && $0.0 < upper }
            .sorted { lhs, rhs in
                if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
                return lhs.1 < rhs.1
            }

        var merged: [(Double, Double)] = []
        for interval in sorted {
            if let last = merged.last, interval.0 <= last.1 {
                merged[merged.count - 1] = (last.0, max(last.1, interval.1))
            } else {
                merged.append(interval)
            }
        }

        var gaps: [(lower: Double, upper: Double)] = []
        var cursor = lower
        for (bMin, bMax) in merged {
            let gapEnd = min(bMin, upper)
            if gapEnd - cursor >= minWidth {
                gaps.append((cursor, gapEnd))
            }
            cursor = max(cursor, bMax)
            if cursor >= upper { break }
        }
        if upper - cursor >= minWidth {
            gaps.append((cursor, upper))
        }
        return gaps
    }
}
