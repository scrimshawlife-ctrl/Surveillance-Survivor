import SurveillanceCore

/// Pure presentation dress inferred from `WorldLayout` obstacle AABBs.
/// Collision remains simulation-owned; this builder never mutates Core state.
enum UrbanDressBuilder {
    /// Thin curb apron around building pads (not the primary street sidewalk).
    static let buildingCurbWidth: Double = 4
    /// Small sidewalk strip on each side of a two-way street (tune once).
    static let streetSidewalkWidth: Double = 6
    /// Minimum two-lane carriageway width between street sidewalks (tune once).
    static let minCarriagewayWidth: Double = 22
    /// Minimum free-band height/width to treat as a full-span street corridor.
    /// Equals sidewalk + carriageway + sidewalk.
    static let minRoadWidth: Double = streetSidewalkWidth * 2 + minCarriagewayWidth

    /// Backward-compatible alias used by older tests (building curb expansion).
    static let sidewalkWidth: Double = buildingCurbWidth

    static func build(layout: WorldLayout, district: DistrictID) -> UrbanDress {
        _ = district // reserved for district-specific widths later
        let buildings: [UrbanBuildingDress] = layout.obstacles.map { o in
            let foot = UrbanRect(center: o.center, halfSize: o.halfSize)
            // Thin pad curb only — primary sidewalks live on street edges.
            let outer = foot.expanded(by: buildingCurbWidth).clamped(to: layout.bounds)
            return UrbanBuildingDress(obstacleID: o.id, footprint: foot, sidewalkOuter: outer)
        }

        let occupied = buildings.map(\.footprint)
        let bounds = layout.bounds

        var roads: [UrbanRect] = []
        var streetSidewalks: [UrbanRect] = []

        for gap in freeGaps(
            lower: bounds.minY,
            upper: bounds.maxY,
            blocked: occupied.map { ($0.minY, $0.maxY) },
            minWidth: minRoadWidth
        ) {
            let split = splitCorridor(
                isHorizontal: true,
                bounds: bounds,
                gapLower: gap.lower,
                gapUpper: gap.upper
            )
            roads.append(split.carriageway)
            streetSidewalks.append(contentsOf: split.sidewalks)
        }

        for gap in freeGaps(
            lower: bounds.minX,
            upper: bounds.maxX,
            blocked: occupied.map { ($0.minX, $0.maxX) },
            minWidth: minRoadWidth
        ) {
            let split = splitCorridor(
                isHorizontal: false,
                bounds: bounds,
                gapLower: gap.lower,
                gapUpper: gap.upper
            )
            roads.append(split.carriageway)
            streetSidewalks.append(contentsOf: split.sidewalks)
        }

        // Intersections: carriageway H×V overlaps only (sidewalks stay edge bands).
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

        // Fallback: single full-bounds corridor dressed as two-way street if no gaps.
        if roads.isEmpty {
            let split = splitCorridor(
                isHorizontal: true,
                bounds: bounds,
                gapLower: bounds.minY,
                gapUpper: bounds.maxY
            )
            roads = [split.carriageway]
            streetSidewalks = split.sidewalks
        }

        // Punch street sidewalks where they cross a perpendicular carriageway so
        // intersections stay asphalt (sidewalks flank streets, not cover them).
        let clippedSidewalks = clipSidewalksAgainstRoads(streetSidewalks, roads: roads)

        // `sidewalks` = street-edge strips only (two-way flanks).
        // Building curb aprons live on `UrbanBuildingDress.sidewalkOuter`.
        return UrbanDress(
            bounds: bounds,
            roads: roads,
            intersections: intersections,
            sidewalks: clippedSidewalks,
            buildings: buildings,
            alleys: []
        )
    }

    // MARK: - Two-way corridor split

    /// Split a free gap into: sidewalk | two-lane carriageway | sidewalk.
    private static func splitCorridor(
        isHorizontal: Bool,
        bounds: WorldBounds,
        gapLower: Double,
        gapUpper: Double
    ) -> (carriageway: UrbanRect, sidewalks: [UrbanRect]) {
        let span = gapUpper - gapLower
        // Prefer fixed small sidewalks; if the gap is tight, keep min carriageway and shrink sidewalks evenly.
        var sw = streetSidewalkWidth
        if span < minRoadWidth {
            sw = max(2, (span - minCarriagewayWidth) / 2)
        }
        let roadLower = gapLower + sw
        let roadUpper = gapUpper - sw
        // Guard degenerate carriageway.
        let safeRoadLower = min(roadLower, roadUpper - 1)
        let safeRoadUpper = max(roadUpper, safeRoadLower + 1)

        if isHorizontal {
            let sidewalkBottom = UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: gapLower, maxY: gapLower + sw
            )
            let sidewalkTop = UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: gapUpper - sw, maxY: gapUpper
            )
            let carriageway = UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: safeRoadLower, maxY: safeRoadUpper
            )
            return (carriageway, [sidewalkBottom, sidewalkTop])
        } else {
            let sidewalkLeft = UrbanRect(
                minX: gapLower, maxX: gapLower + sw,
                minY: bounds.minY, maxY: bounds.maxY
            )
            let sidewalkRight = UrbanRect(
                minX: gapUpper - sw, maxX: gapUpper,
                minY: bounds.minY, maxY: bounds.maxY
            )
            let carriageway = UrbanRect(
                minX: safeRoadLower, maxX: safeRoadUpper,
                minY: bounds.minY, maxY: bounds.maxY
            )
            return (carriageway, [sidewalkLeft, sidewalkRight])
        }
    }

    // MARK: - Sidewalk / road non-overlap

    /// Split full-span sidewalk bands so they do not interior-cover perpendicular carriageways.
    private static func clipSidewalksAgainstRoads(
        _ sidewalks: [UrbanRect],
        roads: [UrbanRect]
    ) -> [UrbanRect] {
        var result: [UrbanRect] = []
        for sw in sidewalks {
            let isHorizontalBand = sw.width >= sw.height
            if isHorizontalBand {
                // Block X ranges of vertical-ish carriageways that cross this Y band.
                let blockers = roads
                    .filter { $0.height > $0.width }
                    .filter { $0.minY < sw.maxY && $0.maxY > sw.minY }
                    .map { ($0.minX, $0.maxX) }
                let spans = freeGaps(
                    lower: sw.minX,
                    upper: sw.maxX,
                    blocked: blockers,
                    minWidth: 2
                )
                for span in spans {
                    result.append(UrbanRect(
                        minX: span.lower, maxX: span.upper,
                        minY: sw.minY, maxY: sw.maxY
                    ))
                }
            } else {
                let blockers = roads
                    .filter { $0.width >= $0.height }
                    .filter { $0.minX < sw.maxX && $0.maxX > sw.minX }
                    .map { ($0.minY, $0.maxY) }
                let spans = freeGaps(
                    lower: sw.minY,
                    upper: sw.maxY,
                    blocked: blockers,
                    minWidth: 2
                )
                for span in spans {
                    result.append(UrbanRect(
                        minX: sw.minX, maxX: sw.maxX,
                        minY: span.lower, maxY: span.upper
                    ))
                }
            }
        }
        return result
    }

    // MARK: - Gap projection

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
