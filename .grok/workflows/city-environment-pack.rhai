let meta = #{
    name: "city-environment-pack",
    description: "Gated city foundation pack with parallel produce streams + skeptic audit",
    when_to_use: "Surveillance Survivor ten-city foundation art (13 runtime textures + docs + map wiring)",
    phases: [
        #{ title: "Inventory", detail: "reuse gate vs global + prior city packs" },
        #{ title: "Produce", detail: "parallel docs + terrain + landmarks + overlays" },
        #{ title: "Wire", detail: "branch, install, GameAssetName/map/projector, tests" },
        #{ title: "Validate", detail: "parallel checker + adversarial skeptic" },
        #{ title: "Report", detail: "completion report and next city" },
    ],
};

let inventory_schema = #{
    "type": "object",
    "required": ["city_slug", "level", "reuse_exact", "generate_missing", "reject_duplicate", "runtime_names", "buckets"],
    "properties": #{
        "city_slug": #{ "type": "string" },
        "level": #{ "type": "integer" },
        "title": #{ "type": "string" },
        "district_id": #{ "type": "string" },
        "reuse_exact": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 40 },
        "generate_missing": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 20 },
        "reject_duplicate": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 30 },
        "runtime_names": #{ "type": "array", "items": #{ "type": "string" }, "minItems": 10, "maxItems": 16 },
        "buckets": #{
            "type": "object",
            "required": ["terrain", "landmarks", "overlays", "decals"],
            "properties": #{
                "terrain": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 6 },
                "landmarks": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
                "overlays": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 6 },
                "decals": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 4 },
            },
        },
        "notes": #{ "type": "string" },
    },
};

let stream_schema = #{
    "type": "object",
    "required": ["stream", "ok", "files", "summary"],
    "properties": #{
        "stream": #{ "type": "string" },
        "ok": #{ "type": "boolean" },
        "files": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 20 },
        "summary": #{ "type": "string" },
        "blockers": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
    },
};

let wire_schema = #{
    "type": "object",
    "required": ["branch", "runtime_count", "docs_dir", "pr_ready", "summary"],
    "properties": #{
        "branch": #{ "type": "string" },
        "runtime_count": #{ "type": "integer" },
        "docs_dir": #{ "type": "string" },
        "pr_ready": #{ "type": "boolean" },
        "summary": #{ "type": "string" },
        "assets_check_ok": #{ "type": "boolean" },
        "tests_ok": #{ "type": "boolean" },
        "blockers": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 12 },
    },
};

let audit_schema = #{
    "type": "object",
    "required": ["pass", "issues", "evidence"],
    "properties": #{
        "pass": #{ "type": "boolean" },
        "issues": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 12 },
        "evidence": #{ "type": "string" },
        "not_recolored_prior_city": #{ "type": "boolean" },
        "filenames_deterministic": #{ "type": "boolean" },
        "missing_list_empty": #{ "type": "boolean" },
    },
};

// --- args ---
let city = if args == () { () } else { args.city };
let level = if args == () { () } else { args.level };
let title = if args == () { () } else { args.title };
let thesis = if args == () { () } else { args.thesis };
let mechanic = if args == () { () } else { args.mechanic };
let district_id = if args == () { () } else { args.district_id };
let prefix = if args == () { () } else { args.prefix };
let next_city = if args == () { () } else { args.next_city };
let open_pr = if args == () { () } else { args.open_pr };

if city == () || level == () || title == () || thesis == () || mechanic == () || district_id == () || prefix == () {
    pause("verification", "Pass args: city, level, title, thesis, mechanic, district_id, prefix. Optional: next_city, open_pr.");
}

let city_s = city;
let level_s = level.to_string();
let title_s = title;
let thesis_s = thesis;
let mechanic_s = mechanic;
let district_s = district_id;
let prefix_s = prefix;
let next_s = if next_city == () { "next campaign city" } else { next_city };
let open_pr_s = if open_pr == () { "none" } else { open_pr };

// ========== Inventory (sequential — needs full picture) ==========
phase("Inventory");

let inv_prompt = "";
inv_prompt += "Inventory agent for Surveillance Survivor city pack. USE list_dir/grep/read_file and read-only shell ls/find. ";
inv_prompt += "Do not invent filenames without listing Resources/RuntimeSprites and docs/cities.\n";
inv_prompt += "City=" + city_s + " level=" + level_s + " title=" + title_s + " districtId=." + district_s + " prefix=" + prefix_s + "\n";
inv_prompt += "Thesis: " + thesis_s + "\nMechanic: " + mechanic_s + "\nOpen PR note: " + open_pr_s + "\n";
inv_prompt += "Propose EXACTLY 13 runtime basenames (no .png) with that prefix: 2 terrain incl skyline as third if needed, ";
inv_prompt += "prefer buckets: terrain (2-3 incl skyline), landmarks (4-5), overlays (3), decals (2). ";
inv_prompt += "Fill buckets.terrain/landmarks/overlays/decals as disjoint partitions of runtime_names. ";
inv_prompt += "Classify reuse_exact / generate_missing / reject_duplicate. Never regenerate player/lpr/guard/boss/blind_spot. ";
inv_prompt += "Return schema JSON only.";

let inv = agent(inv_prompt, #{
    label: "inventory",
    capability_mode: "read-only",
    output_schema: inventory_schema,
});

if inv == () || !inv.success || inv.output == () {
    complete(#{ summary: "Inventory failed", city: city_s, ok: false });
}

let inv_out = inv.output;
let runtime_names = inv_out.runtime_names;
let buckets = inv_out.buckets;
if runtime_names == () || runtime_names.len() < 10 || buckets == () {
    complete(#{ summary: "Inventory incomplete runtime_names/buckets", city: city_s, ok: false, inventory: inv_out });
}

let terrain_names = buckets.terrain;
let landmark_names = buckets.landmarks;
let overlay_names = buckets.overlays;
let decal_names = buckets.decals;
if terrain_names == () { terrain_names = []; }
if landmark_names == () { landmark_names = []; }
if overlay_names == () { overlay_names = []; }
if decal_names == () { decal_names = []; }

log("Inventory ok: " + runtime_names.len().to_string() + " names; parallel produce streams next");

// ========== Produce (PARALLEL fan-out) ==========
phase("Produce");

let names_json = json_encode(runtime_names);
let rej_json = json_encode(inv_out.reject_duplicate);
let style = "2.5D pixel top-down three-quarter orthographic nearest-neighbor; no characters logos text HUD; magenta key for isolated sprites.";

let docs_p = "";
docs_p += "Write Phase-0 docs ONLY for city " + city_s + " under docs/cities/" + city_s + "/. ";
docs_p += "USE write tools. Create REUSE_MATRIX.md, ASSET_INVENTORY.json, FILENAME_MANIFEST.json, COMPLETION_RECEIPT.md, QA_REPORT.md. ";
docs_p += "Title=" + title_s + " thesis=" + thesis_s + " mechanic=" + mechanic_s + " level=" + level_s + ". ";
docs_p += "runtime_names=" + names_json + " reject=" + rej_json + ". ";
docs_p += "Do not generate PNGs. Do not edit Game/ code. Return stream=docs, ok, files list, summary.";

let terr_p = "";
terr_p += "Generate TERRAIN+SKYLINE PNGs only for " + city_s + ". USE image_gen + shell/python to install. ";
terr_p += "Names: " + json_encode(terrain_names) + ". Style: " + style + " ";
terr_p += "Also generate docs-only identity+palette boards into docs/cities/" + city_s + "/assets/ if missing. ";
terr_p += "Install runtime tiles 256² and skyline 1024x384 into Resources/RuntimeSprites and Assets.xcassets imagesets. ";
terr_p += "Do not wire Swift. Return stream=terrain, ok, files, summary. City feel: " + thesis_s;

let land_p = "";
land_p += "Generate LANDMARK+PROP PNGs only for " + city_s + ". USE image_gen + install pipeline. ";
land_p += "Names: " + json_encode(landmark_names) + ". Style: " + style + " solid magenta key backgrounds. ";
land_p += "Install to RuntimeSprites + xcassets. Do not edit Swift. Do not generate terrain. ";
land_p += "Return stream=landmarks, ok, files, summary. Mechanic: " + mechanic_s;

let over_p = "";
over_p += "Generate OVERLAY+DECAL PNGs only for " + city_s + ". USE image_gen + install. ";
over_p += "Overlays: " + json_encode(overlay_names) + " Decals: " + json_encode(decal_names) + ". ";
over_p += "Style: " + style + " transparent overlays on magenta key. Install RuntimeSprites + xcassets. ";
over_p += "Do not edit Swift. Return stream=overlays, ok, files, summary.";

let streams = parallel([
    #{ prompt: docs_p, label: "docs", capability_mode: "read-write", output_schema: stream_schema },
    #{ prompt: terr_p, label: "terrain", capability_mode: "all", output_schema: stream_schema },
    #{ prompt: land_p, label: "landmarks", capability_mode: "all", output_schema: stream_schema },
    #{ prompt: over_p, label: "overlays", capability_mode: "all", output_schema: stream_schema },
]);

let stream_ok = 0;
let stream_fail = 0;
let i = 0;
while i < streams.len() {
    let s = streams[i];
    if s != () && s.success && s.output != () && s.output.ok == true {
        stream_ok += 1;
    } else {
        stream_fail += 1;
    }
    i += 1;
}
log("Produce streams ok=" + stream_ok.to_string() + " fail=" + stream_fail.to_string());

// ========== Wire (sequential integrator) ==========
phase("Wire");

let wire_p = "";
wire_p += "INTEGRATOR for " + city_s + " foundation pack. Prior parallel streams wrote docs and PNGs. ";
wire_p += "USE git, read_file, search_replace, run_terminal_command. ";
wire_p += "1) Ensure branch agent/" + city_s + "-city-environment-pack from LOCAL main (git checkout main; git checkout -B agent/" + city_s + "-city-environment-pack). Do NOT reset to origin/main — local main may be ahead with NYC+LA packs. ";
wire_p += "2) Confirm 13 RuntimeSprites with prefix " + prefix_s + "; fix install if missing from list " + names_json + ". ";
wire_p += "3) Wire GameAssetName for the city in PascalCase (Atlanta for atlanta), VisualAssetMap roles/entries, terrainRole/skylineRole for ." + district_s + ", ";
wire_p += "WorldProjector landmarks/decals/obstacles, validate_visual_assets.sh, VisualAssetMapTests. KEEP all prior city packs (NewYork, LosAngeles, etc.) — ADD Atlanta, do not replace. ";
wire_p += "4) make assets-check && make test. Fix failures. ";
wire_p += "5) Remove any macOS ' 2' duplicate files. Do not push. pr_ready=true only if checks green. ";
wire_p += "Return wire schema JSON.";

let wire = agent(wire_p, #{
    label: "wire",
    capability_mode: "all",
    output_schema: wire_schema,
});

if wire == () || !wire.success || wire.output == () {
    complete(#{ summary: "Wire failed", city: city_s, ok: false, inventory: inv_out, streams_ok: stream_ok });
}

let wire_out = wire.output;
log("Wire: " + wire_out.summary);

// ========== Validate (PARALLEL) ==========
phase("Validate");

let check_p = "";
check_p += "Validate " + city_s + " pack. Run make assets-check and make test. ";
check_p += "Confirm 13 sprites prefix " + prefix_s + " and terrainRole(." + district_s + ") is city-specific. ";
check_p += "pass=true only if both succeed. evidence quotes outputs. names=" + names_json;

let skep_p = "";
skep_p += "Adversarial skeptic for " + city_s + ". Read-only tools. Refute completion. ";
skep_p += "Check recolor/mislabel, deterministic names, no player/lpr under city prefix, docs exist. ";
skep_p += "pass=true only if no real defect. Set not_recolored_prior_city, filenames_deterministic, missing_list_empty.";

let val_panel = parallel([
    #{ prompt: check_p, label: "checker", capability_mode: "execute", output_schema: audit_schema },
    #{ prompt: skep_p, label: "skeptic", capability_mode: "read-only", output_schema: audit_schema },
]);

let checker = if val_panel.len() > 0 { val_panel[0] } else { () };
let skeptic = if val_panel.len() > 1 { val_panel[1] } else { () };
let checker_pass = checker != () && checker.success && checker.output != () && checker.output.pass == true;
let skeptic_pass = skeptic != () && skeptic.success && skeptic.output != () && skeptic.output.pass == true;

// ========== Report ==========
phase("Report");

let report = "";
report += "# City environment pack (parallel produce)\n\n";
report += "- City: " + city_s + " L" + level_s + " — " + title_s + "\n";
report += "- District: ." + district_s + " prefix " + prefix_s + "\n";
report += "- Parallel produce streams ok/fail: " + stream_ok.to_string() + "/" + stream_fail.to_string() + "\n";
report += "- Branch: " + wire_out.branch + " runtime_count=" + wire_out.runtime_count.to_string() + "\n";
report += "- Checker: " + checker_pass.to_string() + " Skeptic: " + skeptic_pass.to_string() + "\n";
report += "- Next: " + next_s + "\n\n";
report += "## Wire summary\n" + wire_out.summary + "\n\n";
if checker != () && checker.success && checker.output != () {
    report += "## Checker\n" + checker.output.evidence + "\n\n";
}
if skeptic != () && skeptic.success && skeptic.output != () {
    report += "## Skeptic\n" + skeptic.output.evidence + "\n\n";
}
report += "Agent budget shape: inventory1 + produce4 parallel + wire1 + validate2 = 8 logical agents.\n";

let path = write_scratch_file("city-pack-report.md", report);
let ok = checker_pass && skeptic_pass && wire_out.pr_ready == true && stream_fail == 0;

complete(#{
    summary: if ok { "Ready: " + city_s } else { "Needs follow-up: " + city_s },
    ok: ok,
    city: city_s,
    parallel_produce: true,
    streams_ok: stream_ok,
    streams_fail: stream_fail,
    branch: wire_out.branch,
    report_path: path,
    report: report,
    inventory: inv_out,
    wire: wire_out,
    checker_pass: checker_pass,
    skeptic_pass: skeptic_pass,
    next_city: next_s,
    agent_slots: 8,
});
