// Factory Verifier MCP Server — H20 Prototype
// Adapter layer that wraps PowerShell verification scripts as MCP tools.
// PROOF OF CONCEPT only. Verified working via node_repl MCP.
// See README.md for full rules and constraints.

const { execSync } = require("child_process");

const CONFIG = {
    repoRoot: process.env.FACTORY_REPO || "C:\\Codex_App_Factory",
    timeout: 30000,
    shell: "powershell",
    shellArgs: ["-NoProfile", "-ExecutionPolicy", "Bypass"]
};

function runPowerShell(scriptPath, args = "") {
    const cmd = `${CONFIG.shell} ${CONFIG.shellArgs.join(" ")} -File "${scriptPath}" ${args}`;
    const result = execSync(cmd, {
        encoding: "utf8",
        timeout: CONFIG.timeout,
        cwd: CONFIG.repoRoot,
        maxBuffer: 1024 * 1024
    });
    return JSON.parse(result);
}

// Tool: factory.verify
function factoryVerify(params = {}) {
    const phase = params.phase || "latest";
    const scriptPath = `${CONFIG.repoRoot}\\scripts\\factoryctl.ps1`;
    const result = runPowerShell(scriptPath, `verify --json`);
    return {
        tool: "factory.verify",
        phase,
        ...result
    };
}

// Tool: factory.validateResourcePack
function validateResourcePack(params = {}) {
    const packPath = params.packPath || `${CONFIG.repoRoot}\\factory-resource-pack`;
    const scriptPath = `${packPath}\\bootstrap\\validate-resource-pack.ps1`;
    const result = runPowerShell(scriptPath);
    return {
        tool: "factory.validateResourcePack",
        packPath,
        ...result
    };
}

// Tool: factory.validateHandoff
function validateHandoff(params = {}) {
    const handoffPath = params.handoffPath || `${CONFIG.repoRoot}\\governance\\factory-state\\session-rotation-handoff.json`;
    const scriptPath = `${CONFIG.repoRoot}\\scripts\\diagnosis\\check-handoff-integrity.ps1`;
    const result = runPowerShell(scriptPath, "-Json");
    return {
        tool: "factory.validateHandoff",
        handoffPath,
        ...result
    };
}

// Safety: FAIL remains FAIL (no conversion to PASS)
function safeResult(result) {
    // Pass-through: never modify verdict
    if (result.verdict === "FAIL" || result.overallVerdict === "FAIL") {
        return { ...result, _note: "FAIL preserved — machine-readable" };
    }
    return result;
}

module.exports = {
    factoryVerify,
    validateResourcePack,
    validateHandoff,
    safeResult,
    CONFIG
};
