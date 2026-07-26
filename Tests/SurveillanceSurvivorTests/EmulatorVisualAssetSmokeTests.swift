import SpriteKit
import Testing
import UIKit
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// Emulator-hosted proof that the visual asset map's MVP textures load from the
/// app bundle and that EntityProjector attaches them for live entity kinds.
/// Physical-device pixel readability remains a separate acceptance item.
@Suite("Emulator visual asset smoke")
struct EmulatorVisualAssetSmokeTests {
    @Test @MainActor func requiredMapAssetsLoadFromSimulatorBundle() {
        let missing = TextureAssetLoader.missingRequiredAssets()
        #expect(missing.isEmpty, "MVP textures missing from host: \(missing)")

        for name in VisualAssetMap.requiredAssetNames {
            #expect(TextureAssetLoader.isAvailable(name), "Unavailable required asset: \(name)")
            #expect(UIImage(named: name) != nil)
        }
    }

    @Test @MainActor func optionalSuspicionTiersLoadWhenAttached() {
        // Attached in v0.2 partial intake; still optionalForMVP so absence must not fail play.
        for tier in 0...5 {
            let name = GameAssetName.SuspicionTierIcon.name(for: tier)
            #expect(VisualAssetMap.requiredAssetNames.contains(name) == false)
            #expect(TextureAssetLoader.isAvailable(name), "Expected attached optional tier glyph: \(name)")
        }
    }

    @Test @MainActor func optionalGuardAndBossSpritesLoadWhenAttached() {
        for name in GameAssetName.optionalEntitySprites {
            #expect(VisualAssetMap.requiredAssetNames.contains(name) == false)
            #expect(TextureAssetLoader.isAvailable(name), "Expected attached optional entity sprite: \(name)")
        }
        for name in GameAssetName.optionalGuardRoster {
            #expect(TextureAssetLoader.isAvailable(name), "Expected attached guard roster sprite: \(name)")
        }
    }

    @Test @MainActor func optionalCombatSpritesLoadWhenAttached() {
        for name in GameAssetName.optionalCombatSprites {
            #expect(VisualAssetMap.requiredAssetNames.contains(name) == false)
            #expect(TextureAssetLoader.isAvailable(name), "Expected attached P0 combat sprite: \(name)")
            #expect(UIImage(named: name) != nil)
        }
    }

    @Test @MainActor func playerMultiFrameExtrasLoadWhenAttached() {
        for name in GameAssetName.Player.multiFrameExtras {
            #expect(TextureAssetLoader.isAvailable(name), "Expected multi-frame player texture: \(name)")
        }
        #expect(PlayerAtlasManifest.validate())
        #expect(PlayerAtlasManifest.allFrameAssetNames.count == 8 + 16)
    }

    @Test @MainActor func optionalEnvironmentPackageLoadsWhenAttached() {
        for name in GameAssetName.optionalEnvironment {
            #expect(VisualAssetMap.requiredAssetNames.contains(name) == false)
            #expect(TextureAssetLoader.isAvailable(name), "Expected attached environment asset: \(name)")
        }
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        let sim = Simulation(seed: 3, district: .wichita)
        scene.installSimulationForTesting(sim)
        #expect(VisualAssetMap.terrainRole(for: .wichita) == .wichitaTerrainArterial)
        #expect(scene.districtName == DistrictID.wichita.cityName)
    }

    @Test @MainActor func reservedFutureAssetsRemainOptional() {
        // P0 combat stills graduated to optionalCombatSprites (#49); list may be empty.
        for name in GameAssetName.reservedFuture {
            #expect(VisualAssetMap.requiredAssetNames.contains(name) == false)
            _ = TextureAssetLoader.isAvailable(name)
        }
    }

    @Test @MainActor func entityProjectorAttachesProjectileAndDeployableSprites() {
        var state = RunState(seed: 0xC0A7, district: .wichita)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(
                id: 10,
                kind: .projectile,
                position: .init(x: 20, y: 0),
                velocity: .init(x: 80, y: 0),
                health: 1,
                radius: 4,
                sourceWeapon: .kineticCountermeasure
            ),
            Entity(id: 11, kind: .mirrorArray, position: .init(x: 40, y: 0), health: 40, radius: 20),
            Entity(id: 12, kind: .signalFlood, position: .init(x: 70, y: 0), health: 40, radius: 28)
        ]
        let simulation = Simulation(state: state, rngSeed: 0xC0A7)
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(simulation)

        guard let projectile = scene.childNode(withName: "entity-10") as? SKSpriteNode else {
            Issue.record("projectile should project as SKSpriteNode when projectile_default is present")
            return
        }
        #expect(projectile.userData?["asset"] as? String == GameAssetName.Projectile.default)

        guard let mirror = scene.childNode(withName: "entity-11") as? SKSpriteNode else {
            Issue.record("mirror array should project as SKSpriteNode when texture is present")
            return
        }
        // Active-state strip is preferred when 3-state art is attached.
        let mirrorAsset = mirror.userData?["asset"] as? String
        #expect(
            mirrorAsset == GameAssetName.Deployable.mirrorArray
                || mirrorAsset == GameAssetName.Deployable.mirrorArrayActive
        )

        guard let flood = scene.childNode(withName: "entity-12") as? SKSpriteNode else {
            Issue.record("signal flood should project as SKSpriteNode when texture is present")
            return
        }
        let floodAsset = flood.userData?["asset"] as? String
        #expect(
            floodAsset == GameAssetName.Deployable.signalFlood
                || floodAsset == GameAssetName.Deployable.signalFloodActive
        )
    }

    @Test @MainActor func entityProjectorUsesExpendedDeployableStateAfterExpiry() {
        // Isolate the former tick:0 bug: healthy deployable past effectExpiresAtTick
        // must project expended (dimmed) rather than active.
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        let projector = EntityProjector()
        let mirror = Entity(
            id: 31,
            kind: .mirrorArray,
            position: .init(x: 10, y: 0),
            health: 40,
            radius: 20,
            effectExpiresAtTick: 1
        )
        let display: [UInt64: PresentationPipeline.DisplaySample] = [
            31: .init(
                position: CGPoint(x: 10, y: 0),
                heading: 0,
                animationState: .expended,
                secondary: .zero
            )
        ]
        projector.synchronize(entities: [mirror], display: display, tick: 2, in: scene)
        guard let node = scene.childNode(withName: "entity-31") as? SKSpriteNode else {
            Issue.record("expired mirror should project as SKSpriteNode")
            return
        }
        let asset = node.userData?["asset"] as? String
        #expect(
            asset == GameAssetName.Deployable.mirrorArrayExpended
                || asset == GameAssetName.Deployable.mirrorArray,
            "expected expended (or fallback) stem, got \(asset ?? "nil")"
        )
        #expect(node.alpha < 1, "expended deployables dim alpha")

        // Without a display sample, tick alone must still resolve expended.
        let flood = Entity(
            id: 32,
            kind: .signalFlood,
            position: .init(x: 40, y: 0),
            health: 40,
            radius: 28,
            effectExpiresAtTick: 1
        )
        projector.synchronize(entities: [flood], display: [:], tick: 2, in: scene)
        guard let floodNode = scene.childNode(withName: "entity-32") else {
            Issue.record("expired flood should project a node")
            return
        }
        #expect(floodNode.alpha < 1, "tick-driven expended flood must dim without display sample")
    }

    @Test @MainActor func entityProjectorAttachesGuardAndBossSprites() {
        var state = RunState(seed: 0x601, district: .wichita)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(
                id: 2,
                kind: .securityGuard,
                guardArchetype: .tacticalPolo,
                position: .init(x: 40, y: 0),
                health: 18,
                radius: 14
            ),
            Entity(id: 3, kind: .boss, position: .init(x: 80, y: 0), health: 200, radius: 42)
        ]
        let simulation = Simulation(state: state, rngSeed: 0x601)
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(simulation)

        guard let guardNode = scene.childNode(withName: "entity-2") as? SKSpriteNode else {
            Issue.record("guard should project as SKSpriteNode when guard_default is present")
            return
        }
        // Roster skins select by archetype when attached.
        #expect(
            guardNode.userData?["asset"] as? String == GameAssetName.Guard.tacticalPolo
                || guardNode.userData?["asset"] as? String == GameAssetName.Guard.default
        )

        guard let bossNode = scene.childNode(withName: "entity-3") as? SKSpriteNode else {
            Issue.record("boss should project as SKSpriteNode when boss_default is present")
            return
        }
        #expect(bossNode.userData?["asset"] as? String == GameAssetName.Boss.default)
    }

    @Test @MainActor func entityProjectorAttachesMappedPlayerAndLPRSprites() {
        let simulation = Simulation(seed: 0xA55E7, district: .wichita)
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(simulation)

        guard let player = simulation.state.entities.first(where: { $0.kind == .player }) else {
            Issue.record("expected player entity")
            return
        }
        guard let playerNode = scene.childNode(withName: "entity-\(player.id)") as? SKSpriteNode else {
            Issue.record("player should project as SKSpriteNode when player textures are present")
            return
        }
        let playerAsset = playerNode.userData?["asset"] as? String
        let expectedPlayer = VisualAssetMap.assetName(
            VisualAssetMap.playerRole(
                velocityX: player.velocity.x,
                velocityY: player.velocity.y,
                heading: player.heading
            )
        )
        #expect(playerAsset == expectedPlayer)
        #expect(GameAssetName.Player.all.contains(playerAsset ?? ""))
        #expect(TextureAssetLoader.isAvailable(playerAsset!))

        guard let camera = simulation.state.entities.first(where: { $0.kind == .cameraPole }) else {
            Issue.record("Wichita profile should start with LPR poles")
            return
        }
        guard let container = scene.childNode(withName: "entity-\(camera.id)") else {
            Issue.record("camera pole container missing from scene")
            return
        }
        guard let body = container.childNode(withName: "body") as? SKSpriteNode else {
            Issue.record("LPR body should be an SKSpriteNode when intact texture is present")
            return
        }
        let bodyAsset = body.userData?["asset"] as? String
        #expect(bodyAsset == GameAssetName.LPRCamera.intact)
        #expect(TextureAssetLoader.isAvailable(bodyAsset!))
    }

    @Test @MainActor func extractionDecalUsesMappedBlindSpotTextureWhenOpened() {
        var state = RunState(seed: 48, district: .wichita)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
        ]
        var simulation = Simulation(state: state, rngSeed: 48)
        _ = simulation.step(input: .init(autoFireEnabled: false))
        #expect(simulation.state.extractionOpen)

        guard let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
            Issue.record("expected Blind Spot entity after boss defeat")
            return
        }

        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(simulation)
        guard let node = scene.childNode(withName: "entity-\(extraction.id)") as? SKSpriteNode else {
            Issue.record("extraction should project as SKSpriteNode when blind_spot_decal is present")
            return
        }
        let asset = node.userData?["asset"] as? String
        #expect(asset == GameAssetName.Environment.blindSpotDecal)
    }
}
