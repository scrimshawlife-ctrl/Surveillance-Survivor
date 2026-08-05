import SurveillanceCore

/// Pure presentation dress inferred from `WorldLayout` obstacle AABBs.
/// Collision remains simulation-owned; this builder never mutates Core state.
enum UrbanDressBuilder {
    /// Thin curb apron around building pads (not the primary street sidewalk).
    static let buildingCurbWidth: Double = 4
    /// Sidewalk strip on each side of a street (satellite curb walk).
    static let streetSidewalkWidth: Double = 5
    /// Curb-side parking band between sidewalk and travel lanes (when gap allows).
    static let streetParkingWidth: Double = 4
    /// Minimum two-lane travel carriageway width (tune once).
    static let minCarriagewayWidth: Double = 22
    /// Minimum free-band to treat as a street corridor (sidewalk + carriage + sidewalk).
    /// Parking is added when the gap is wide enough; it is not required to form a street.
    static let minRoadWidth: Double = streetSidewalkWidth * 2 + minCarriagewayWidth

    /// Backward-compatible alias (building curb expansion).
    static let sidewalkWidth: Double = buildingCurbWidth

    static func build(layout: WorldLayout, district: DistrictID) -> UrbanDress {
        _ = district
        let buildings: [UrbanBuildingDress] = layout.obstacles.map { o in
            let foot = UrbanRect(center: o.center, halfSize: o.halfSize)
            let outer = foot.expanded(by: buildingCurbWidth).clamped(to: layout.bounds)
            return UrbanBuildingDress(obstacleID: o.id, footprint: foot, sidewalkOuter: outer)
        }

        let occupied = buildings.map(\.footprint)
        let bounds = layout.bounds

        var roads: [UrbanRect] = []
        var streetSidewalks: [UrbanRect] = []
        var streetParking: [UrbanRect] = []

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
            streetParking.append(contentsOf: split.parking)
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
            streetParking.append(contentsOf: split.parking)
        }

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

        if roads.isEmpty {
            let split = splitCorridor(
                isHorizontal: true,
                bounds: bounds,
                gapLower: bounds.minY,
                gapUpper: bounds.maxY
            )
            roads = [split.carriageway]
            streetSidewalks = split.sidewalks
            streetParking = split.parking
        }

        // Punch flanks where they cross perpendicular carriageways (intersections stay asphalt).
        let clippedSidewalks = clipBandsAgainstRoads(streetSidewalks, roads: roads)
        let clippedParking = clipBandsAgainstRoads(streetParking, roads: roads)

        return UrbanDress(
            bounds: bounds,
            roads: roads,
            intersections: intersections,
            sidewalks: clippedSidewalks,
            parking: clippedParking,
            buildings: buildings,
            alleys: []
        )
    }

    // MARK: - Satellite street cross-section

    /// Split free gap into: sidewalk | parking? | carriageway | parking? | sidewalk.
    private static func splitCorridor(
        isHorizontal: Bool,
        bounds: WorldBounds,
        gapLower: Double,
        gapUpper: Double
    ) -> (carriageway: UrbanRect, sidewalks: [UrbanRect], parking: [UrbanRect]) {
        let span = gapUpper - gapLower
        var sw = streetSidewalkWidth
        var pk = streetParkingWidth

        // Prefer full section when space allows; drop parking before shrinking sidewalks.
        let fullWithParking = sw * 2 + pk * 2 + minCarriagewayWidth
        if span < fullWithParking {
            pk = 0
        }
        let minWithSidewalks = sw * 2 + minCarriagewayWidth
        if span < minWithSidewalks {
            sw = max(2, (span - minCarriagewayWidth) / 2)
            pk = 0
        }

        let flank = sw + pk
        let roadLower = gapLower + flank
        let roadUpper = gapUpper - flank
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
            var parking: [UrbanRect] = []
            if pk > 0.5 {
                parking = [
                    UrbanRect(
                        minX: bounds.minX, maxX: bounds.maxX,
                        minY: gapLower + sw, maxY: gapLower + sw + pk
                    ),
                    UrbanRect(
                        minX: bounds.minX, maxX: bounds.maxX,
                        minY: gapUpper - sw - pk, maxY: gapUpper - sw
                    ),
                ]
            }
            let carriageway = UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: safeRoadLower, maxY: safeRoadUpper
            )
            return (carriageway, [sidewalkBottom, sidewalkTop], parking)
        } else {
            let sidewalkLeft = UrbanRect(
                minX: gapLower, maxX: gapLower + sw,
                minY: bounds.minY, maxY: bounds.maxY
            )
            let sidewalkRight = UrbanRect(
                minX: gapUpper - sw, maxX: gapUpper,
                minY: bounds.minY, maxY: bounds.maxY
            )
            var parking: [UrbanRect] = []
            if pk > 0.5 {
                parking = [
                    UrbanRect(
                        minX: gapLower + sw, maxX: gapLower + sw + pk,
                        minY: bounds.minY, maxY: bounds.maxY
                    ),
                    UrbanRect(
                        minX: gapUpper - sw - pk, maxX: gapUpper - sw,
                        minY: bounds.minY, maxY: bounds.maxY
                    ),
                ]
            }
            let carriageway = UrbanRect(
                minX: safeRoadLower, maxX: safeRoadUpper,
                minY: bounds.minY, maxY: bounds.maxY
            )
            return (carriageway, [sidewalkLeft, sidewalkRight], parking)
        }
    }

    // MARK: - Band / road non-overlap

    private static func clipBandsAgainstRoads(
        _ bands: [UrbanRect],
        roads: [UrbanRect]
    ) -> [UrbanRect] {
        var result: [UrbanRect] = []
        for band in bands {
            let isHorizontalBand = band.width >= band.height
            if isHorizontalBand {
                let blockers = roads
                    .filter { $0.height > $0.width }
                    .filter { $0.minY < band.maxY && $0.maxY > band.minY }
                    .map { ($0.minX, $0.maxX) }
                let spans = freeGaps(
                    lower: band.minX,
                    upper: band.maxX,
                    blocked: blockers,
                    minWidth: 2
                )
                for span in spans {
                    result.append(UrbanRect(
                        minX: span.lower, maxX: span.upper,
                        minY: band.minY, maxY: band.maxY
                    ))
                }
            } else {
                let blockers = roads
                    .filter { $0.width >= $0.height }
                    .filter { $0.minX < band.maxX && $0.maxX > band.minX }
                    .map { ($0.minY, $0.maxY) }
                let spans = freeGaps(
                    lower: band.minY,
                    upper: band.maxY,
                    blocked: blockers,
                    minWidth: 2
                )
                for span in spans {
                    result.append(UrbanRect(
                        minX: band.minX, maxX: band.maxX,
                        minY: span.lower, maxY: span.upper
                    ))
                }
            }
        }
        return result
    }

    // MARK: - Gap projection

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
