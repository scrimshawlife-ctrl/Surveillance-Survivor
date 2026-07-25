let meta = #{
    name: "continue-ss",
    description: "Surveillance Survivor continuation: tip inventory, dual-lane status, parallel audits, next package",
    when_to_use: "Continue SS from docs — launch blockers, agent-safe work, board/gate hygiene",
    phases: [
        #{ title: "Inventory", detail: "tip SHA, boards, open PRs, art ship_gate" },
        #{ title: "Audit", detail: "parallel launch blockers + agent residuals + gate honesty" },
        #{ title: "Synthesize", detail: "ranked next package + write continuation report" },
    ],
};

let inventory_schema = #{
    "type": "object",
    "required": ["tip_short", "tip_full", "ship_gate", "open_prs", "device_smoke_recent", "summary"],
    "properties": #{
        "tip_short": #{ "type": "string" },
        "tip_full": #{ "type": "string" },
        "ship_gate": #{ "type": "string" },
        "open_prs": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 12 },
        "device_smoke_recent": #{ "type": "boolean" },
        "summary": #{ "type": "string" },
        "blockers": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 12 },
    },
};

let audit_schema = #{
    "type": "object",
    "required": ["lane", "ok", "findings", "recommended_actions", "evidence"],
    "properties": #{
        "lane": #{ "type": "string" },
        "ok": #{ "type": "boolean" },
        "findings": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 12 },
        "recommended_actions": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 10 },
        "evidence": #{ "type": "string" },
        "agent_safe": #{ "type": "boolean" },
    },
};

let plan_schema = #{
    "type": "object",
    "required": ["priority", "agent_next", "operator_next", "owner_next", "do_not", "report_markdown"],
    "properties": #{
        "priority": #{ "type": "string" },
        "agent_next": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
        "operator_next": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
        "owner_next": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
        "do_not": #{ "type": "array", "items": #{ "type": "string" }, "maxItems": 8 },
        "report_markdown": #{ "type": "string" },
    },
};

// --- args ---
let lane = "audit";
if args != () && args.lane != () {
    lane = args.lane;
}
log("continue-ss lane=" + lane);

// ========== Inventory ==========
phase("Inventory");

let inv_prompt = "";
inv_prompt += "You are inventorying Surveillance Survivor at /Users/appliedalchemylabs/Documents/Surveillance-Survivor.\n";
inv_prompt += "Use bash/git/read_file/grep tools — do not invent tip SHAs.\n";
inv_prompt += "Required reads:\n";
inv_prompt += "1. git rev-parse HEAD and --short; git status -sb; git log --oneline -8\n";
inv_prompt += "2. docs/REPO_STATUS.md, docs/LAUNCH_OPERATOR_PACKET.md, docs/CONTINUATION_PLAN.md\n";
inv_prompt += "3. docs/art_qa/art_qa_audit.json (ship_gate field)\n";
inv_prompt += "4. docs/DEVICE_TEST_LOG.md (latest deployment evidence)\n";
inv_prompt += "5. gh pr list --state open --limit 10 (or note if unavailable)\n";
inv_prompt += "6. make art-qa-check if feasible (or read JSON only)\n";
inv_prompt += "Return tip_short, tip_full, ship_gate, open_prs as strings, device_smoke_recent true if 2026-07-25+ deploy logged, summary, blockers.\n";
inv_prompt += "Empty open_prs is valid if none open.\n";

let inv = agent(inv_prompt, #{
    label: "inventory",
    capability_mode: "execute",
    output_schema: inventory_schema,
});

if inv == () || !inv.success || inv.output == () {
    pause("infra", "Inventory agent failed — check repo access and resume.");
}

let tip = inv.output.tip_short;
let gate = inv.output.ship_gate;
log("tip=" + tip + " ship_gate=" + gate);

// ========== Parallel audits ==========
phase("Audit");

let jobs = [];

// Launch / operator blockers
let p_launch = "";
p_launch += "Read docs/LAUNCH_OPERATOR_PACKET.md, docs/RELEASE_READINESS.md, docs/DEVICE_TEST_LOG.md, docs/ART_DEVICE_QA_CHECKLIST.md.\n";
p_launch += "Tip under inventory is " + tip + ". ship_gate is " + gate + ".\n";
p_launch += "Use read_file/grep only. List concrete launch blockers vs done.\n";
p_launch += "lane must be the string launch. agent_safe=false for any human device/store/audio step.\n";
p_launch += "recommended_actions: ordered next human steps only. evidence: file:line or section names you read.\n";
jobs.push(#{
    prompt: p_launch,
    label: "audit-launch",
    capability_mode: "read-only",
    output_schema: audit_schema,
});

// Agent-safe residuals
let p_agent = "";
p_agent += "Read docs/CONTINUATION_PLAN.md dual-lane agent section, docs/HALLMARK_HUD_AUDIT.md, docs/ART_QA_PERCEPTION_AUDIT.md residual findings.\n";
p_agent += "Inspect App/ for system Form leftovers and HUD chrome. Tip=" + tip + ".\n";
p_agent += "Use read_file/grep. lane=agent. agent_safe=true only for code/docs without inventing PNG/device/audio.\n";
p_agent += "findings: agent-doable residuals. recommended_actions: max 6 concrete tasks.\n";
p_agent += "Do NOT invent store URLs or device receipts.\n";
jobs.push(#{
    prompt: p_agent,
    label: "audit-agent",
    capability_mode: "read-only",
    output_schema: audit_schema,
});

// Gate honesty
let p_gate = "";
p_gate += "Read docs/art_qa/art_qa_audit.json and scripts/validate_art_qa_package.py.\n";
p_gate += "Confirm ship_gate is ART_EVIDENCE_INSUFFICIENT unless device_evidence_paths exist.\n";
p_gate += "lane=gates. ok=true only if honesty rules hold. evidence=paths read.\n";
p_gate += "recommended_actions for keeping make art-qa-check green.\n";
jobs.push(#{
    prompt: p_gate,
    label: "audit-gates",
    capability_mode: "read-only",
    output_schema: audit_schema,
});

// Gameplay loop vs docs (cameras / upgrades)
let p_loop = "";
p_loop += "Read docs/WEAPON_SYSTEM_DESIGN.md (grid-breaking, shards, upgrades) and Sources/SurveillanceCore/Simulation.swift rotateCameraPoles + dataShards.\n";
p_loop += "Confirm design: stationary LPR scan, destroy cameras for shards/upgrade draft, no mid-run coin shop.\n";
p_loop += "lane=gameplay. findings: mismatches only. agent_safe for copy/HUD wording only.\n";
jobs.push(#{
    prompt: p_loop,
    label: "audit-gameplay",
    capability_mode: "read-only",
    output_schema: audit_schema,
});

let audits = parallel(jobs);

// ========== Synthesize ==========
phase("Synthesize");

// Dry-run and host typings may not expose parallel() as a Rhai array; encode wholesale.
let audit_blob = "";
if audits != () {
    audit_blob += json_encode(audits);
} else {
    audit_blob += "(parallel audits empty)";
}

let syn = "";
syn += "Synthesize a continuation plan for Surveillance Survivor.\n";
syn += "Inventory tip=" + tip + " ship_gate=" + gate + ".\n";
syn += "Inventory summary: " + inv.output.summary + "\n";
syn += "Audit extracts:\n" + audit_blob + "\n";
syn += "Read docs/CONTINUATION_PLAN.md and docs/LAUNCH_OPERATOR_PACKET.md once more if needed.\n";
syn += "Produce report_markdown: full markdown with sections Inventory, Launch blockers, Agent residuals, Ranked next, Gates.\n";
syn += "priority: one of launch|agent|blocked.\n";
syn += "agent_next / operator_next / owner_next: concrete bullets.\n";
syn += "do_not: invent device logs, ART_SHIP_APPROVED without evidence, system-sound audio, city 11.\n";
syn += "Use tools to verify any claim about open files.\n";

let plan = agent(syn, #{
    label: "synthesize",
    capability_mode: "read-only",
    output_schema: plan_schema,
});

if plan == () || !plan.success || plan.output == () {
    pause("verification", "Synthesis failed — resume to retry.");
}

let report = "# Surveillance Survivor continuation (stub)\n";
if plan.output.report_markdown != () {
    report = plan.output.report_markdown;
}

let pri = "audit";
if plan.output.priority != () {
    pri = plan.output.priority;
}
log("priority=" + pri);

// Optional human gate when launch is the priority (skipped when priority missing in dry-run)
if pri == "launch" || pri == "blocked" {
    await_user("user", "Continuation priority is " + pri + ". Operator/owner steps cannot be automated. Resume after device/store/audio progress, or ask agent to do agent_next only.");
}

// Report body returned on complete (scratch write is live-run only via host).
complete(#{
    tip: tip,
    ship_gate: gate,
    priority: pri,
    report: report,
    agent_next: plan.output.agent_next,
    operator_next: plan.output.operator_next,
    owner_next: plan.output.owner_next,
    do_not: plan.output.do_not,
});
