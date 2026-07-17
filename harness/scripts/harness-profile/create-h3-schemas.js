var fs = require("fs");
var harness = "C:/Codex_App_Factory/harness";

// ===== Schema 1: project-profile.schema.json =====
var profileSchema = {
    schemaVersion: "H3-R1",
    title: "Project Profile Schema",
    type: "object",
    required: ["profileId","profileName","projectType","defaultWorkerRoles","defaultAcceptanceLayers","defaultComplexityBudget","recommendedArtifacts","forbiddenSimplifications","profileVersion"],
    properties: {
        profileId: { type: "string" },
        profileName: { type: "string" },
        projectType: { type: "string", enum: ["local-http-app","cli-workflow","data-pipeline","custom"] },
        defaultWorkerRoles: { type: "array", items: { type: "object", properties: { roleId: {type:"string"}, roleName: {type:"string"}, responsibilities: {type:"array",items:{type:"string"}} } } },
        defaultAcceptanceLayers: { type: "array", items: { type: "string" } },
        defaultComplexityBudget: { type: "object", required: ["minimumWorkers","minimumTasks","minimumJsFiles","minimumNamedExports","minimumCrossWorkerDeps","minimumScenarios"], properties: { minimumWorkers:{type:"integer",minimum:1}, minimumTasks:{type:"integer",minimum:1}, minimumJsFiles:{type:"integer",minimum:1}, minimumNamedExports:{type:"integer",minimum:1}, minimumCrossWorkerDeps:{type:"integer",minimum:0}, minimumScenarios:{type:"integer",minimum:1} } },
        recommendedArtifacts: { type: "array", items: { type: "string" } },
        forbiddenSimplifications: { type: "array", items: { type: "string" } },
        requiredArchitecturePatterns: { type: "array", items: { type: "string" } },
        defaultFailureModes: { type: "array", items: { type: "string" } },
        profileVersion: { type: "string" }
    }
};
fs.writeFileSync(harness + "/schemas/harness-profile/project-profile.schema.json", JSON.stringify(profileSchema,null,2),"utf8");

// ===== Schema 2: domain-skill-pack.schema.json =====
var domainSkillSchema = {
    schemaVersion: "H3-R1",
    title: "Domain Skill Pack Schema",
    type: "object",
    required: ["domainId","domainName","domainVersion","glossary","domainEntities","workflows","businessRules","invariants","forbiddenAssumptions","requiredWorkerResponsibilities","requiredDomainScenarios"],
    properties: {
        domainId: { type: "string" },
        domainName: { type: "string" },
        domainVersion: { type: "string" },
        domainBrief: { type: "string" },
        glossary: { type: "array", items: { type: "object", properties: { term:{type:"string"}, definition:{type:"string"}, entity:{type:"boolean"} } } },
        domainEntities: { type: "array", items: { type: "object", properties: { entityId:{type:"string"}, entityName:{type:"string"}, fields:{type:"array",items:{type:"string"}}, primaryKey:{type:"string"}, constraints:{type:"array",items:{type:"string"}} } } },
        workflows: { type: "array", items: { type: "object", properties: { workflowId:{type:"string"}, name:{type:"string"}, steps:{type:"array",items:{type:"string"}}, involvedEntities:{type:"array",items:{type:"string"}} } } },
        businessRules: { type: "array", items: { type: "object", required: ["ruleId","description","severity","affectedEntities","positiveExamples","negativeExamples","acceptanceImplication"], properties: { ruleId:{type:"string"}, description:{type:"string"}, severity:{type:"string",enum:["critical","high","medium","low"]}, affectedEntities:{type:"array",items:{type:"string"}}, positiveExamples:{type:"array",items:{type:"string"}}, negativeExamples:{type:"array",items:{type:"string"}}, acceptanceImplication:{type:"string"} } } },
        invariants: { type: "array", items: { type: "string" } },
        edgeCases: { type: "array", items: { type: "string" } },
        exampleData: { type: "array", items: { type: "object", properties: { scenario:{type:"string"}, data:{type:"object"} } } },
        forbiddenAssumptions: { type: "array", items: { type: "string" } },
        requiredWorkerResponsibilities: { type: "array", items: { type: "object", properties: { workerRole:{type:"string"}, responsibilities:{type:"array",items:{type:"string"}}, assignedEntities:{type:"array",items:{type:"string"}} } } },
        requiredDomainScenarios: { type: "array", items: { type: "string" } }
    }
};
fs.writeFileSync(harness + "/schemas/harness-profile/domain-skill-pack.schema.json", JSON.stringify(domainSkillSchema,null,2),"utf8");

// ===== Schema 3: domain-verifier-pack.schema.json =====
var verifierPackSchema = {
    schemaVersion: "H3-R1",
    title: "Domain Verifier Pack Schema",
    type: "object",
    required: ["verifierPackId","domainId","acceptanceScenarios","negativeControls","requiredEvidence","domainSpecificFailureModes"],
    properties: {
        verifierPackId: { type: "string" },
        domainId: { type: "string" },
        acceptanceScenarios: { type: "array", items: { type: "object", required: ["scenarioId","description","requiredInputs","expectedOutputs","evidencePath","failureClassification"], properties: { scenarioId:{type:"string"}, description:{type:"string"}, requiredInputs:{type:"array",items:{type:"string"}}, expectedOutputs:{type:"array",items:{type:"string"}}, evidencePath:{type:"string"}, failureClassification:{type:"string"}, invariantCoverage:{type:"array",items:{type:"string"}} } } },
        negativeControls: { type: "array", items: { type: "object", required: ["negativeId","targetsScenario","injectedFault","expectedFailureClass","mustKeepOtherGatesPassing"], properties: { negativeId:{type:"string"}, targetsScenario:{type:"string"}, injectedFault:{type:"string"}, expectedFailureClass:{type:"string"}, mustKeepOtherGatesPassing:{type:"boolean"} } } },
        requiredEvidence: { type: "array", items: { type: "string" } },
        domainSpecificFailureModes: { type: "array", items: { type: "string" } },
        invariantChecks: { type: "array", items: { type: "object", properties: { invariant:{type:"string"}, scenarioId:{type:"string"}, negativeId:{type:"string"} } } },
        reportRequirements: { type: "array", items: { type: "string" } }
    }
};
fs.writeFileSync(harness + "/schemas/harness-profile/domain-verifier-pack.schema.json", JSON.stringify(verifierPackSchema,null,2),"utf8");

console.log("3 schemas created");
