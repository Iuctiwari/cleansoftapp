import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const failures = [];
const backendApps = ["api-gateway","auth-service","tenant-service","branch-service","user-service","customer-service","service-service","order-service","payment-service","expense-service","notification-service","scheduler-service","report-service","audit-service","search-service"];
const packages = ["common","database","config","types","logger","utils","constants","shared","ui"];
const planningDocuments = ["SOFTWARE_IDEA.md","BUSINESS_REQUIREMENTS.md","TARGET_USERS.md","BUSINESS_GOALS.md","FEATURE_LIST.md","SYSTEM_ARCHITECTURE.md","TECH_STACK.md","DATABASE_DESIGN.md","API_DESIGN.md","MODULE_BREAKDOWN.md","MICROSERVICES.md","RBAC.md","MULTI_TENANCY.md","EVENT_ARCHITECTURE.md","SECURITY_ARCHITECTURE.md","FILE_STORAGE.md","NOTIFICATION_ARCHITECTURE.md","CODING_GUIDELINES.md","NAMING_CONVENTIONS.md","ROADMAP.md","SPRINT_PLAN.md","MILESTONES.md","PLAN_AUDIT.md","ROADMAP_AUDIT.md","PROJECT_BIBLE.md","DIRECTORY_GUIDE.md","DOMAIN_MODEL.md","ENTITY_RELATIONSHIP.md"];
const phasePrompts = ["AUDIT_PHASE_PROMPT.md","PHASE_0_FOUNDATION.md","PHASE_1_SOFTWARE_IDEA.md","PHASE_2_SYSTEM_PLANNING.md","PHASE_3_PLAN_AUDIT.md","PHASE_4_IMPLEMENTATION_ROADMAP.md","PHASE_5_ROADMAP_AUDIT.md","PHASE_6_IMPLEMENTATION_PROMPTS.md","PHASE_7_PROMPT_ENGINEERING.md","PHASE_8_PLATFORM_SETUP.md","PHASE_9_AUTH.md","PHASE_10_TENANTS.md","PHASE_11_BRANCHES.md","PHASE_12_USERS.md","PHASE_13_CUSTOMERS.md","PHASE_14_SERVICES.md","PHASE_15_ORDERS.md","PHASE_16_PAYMENTS.md","PHASE_17_NOTIFICATIONS.md","PHASE_18_EXPENSES.md","PHASE_19_REPORTS.md","PHASE_20_DASHBOARD.md","PHASE_21_SEARCH.md","PHASE_22_SETTINGS.md","PHASE_23_TESTING.md","PHASE_24_DEPLOYMENT.md","PHASE_25_RELEASE.md"];
const sections = ["Purpose","Scope","Inputs","Outputs","Dependencies","Deliverables","Acceptance Criteria","Notes"];
const exactServiceEntries = [".env.example", "README.md", "package.json", "src", "test", "tsconfig.json"].sort();

function exists(relativePath, type = "file") {
  const target = path.join(root, relativePath);
  const ok = fs.existsSync(target) && (type === "directory"
    ? fs.statSync(target).isDirectory()
    : fs.statSync(target).isFile());
  if (!ok) failures.push("Missing " + type + ": " + relativePath);
}

function walk(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if ([".git", "node_modules", ".dart_tool", ".turbo", "dist", "build"].includes(entry.name)) continue;
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...walk(target));
    else files.push(target);
  }
  return files;
}

for (const directory of ["apps", "packages", "docs", "ERP-PLANNING", "docker", "infra", "scripts", ".github"]) {
  exists(directory, "directory");
}
for (const file of ["README.md", "LICENSE", ".gitignore", ".editorconfig", ".prettierrc", ".eslintrc", "package.json", "pnpm-workspace.yaml", "turbo.json", "docker-compose.yml", ".env.example"]) {
  exists(file);
}

for (const app of backendApps) {
  const base = path.join(root, "apps", "backend", app);
  exists("apps/backend/" + app, "directory");
  if (fs.existsSync(base)) {
    const actual = fs.readdirSync(base).sort();
    if (JSON.stringify(actual) !== JSON.stringify(exactServiceEntries)) {
      failures.push("Unexpected service contents: " + app + " => " + actual.join(", "));
    }
  }
}

for (const packageName of packages) {
  for (const entry of ["README.md", "package.json", "tsconfig.json"]) {
    exists("packages/" + packageName + "/" + entry);
  }
  exists("packages/" + packageName + "/src", "directory");
}
for (const document of planningDocuments) exists("ERP-PLANNING/" + document);
for (const prompt of phasePrompts) exists("ERP-PLANNING/phase-prompts/" + prompt);

for (const file of walk(root).filter((target) => target.toLowerCase().endsWith(".md"))) {
  const lines = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n").split("\n");
  if (!lines[0]?.startsWith("# ")) failures.push("Missing Markdown title: " + path.relative(root, file));
  for (const section of sections) {
    const heading = "## " + section;
    const index = lines.indexOf(heading);
    const next = index < 0 ? undefined : lines.slice(index + 1).find((line) => line.trim());
    if (index < 0 || next !== "TODO: " + section + ".") {
      failures.push("Invalid Markdown section " + section + ": " + path.relative(root, file));
    }
  }
  const unexpected = lines.find((line) => {
    const value = line.trim();
    return value && !value.startsWith("# ") && !value.startsWith("## ") && !value.startsWith("TODO:");
  });
  if (unexpected) failures.push("Non-placeholder Markdown content: " + path.relative(root, file));
}

const sourceFiles = walk(path.join(root, "apps")).filter((target) => /\.(ts|dart)$/.test(target));
const forbidden = [/@Controller\s*\(/, /@(Get|Post|Put|Patch|Delete)\s*\(/, /\bclass\s+\w*Service\b/, /\bMaterialApp\s*\(/, /\bScaffold\s*\(/, /extends\s+(StatelessWidget|StatefulWidget)/];
for (const file of sourceFiles) {
  const content = fs.readFileSync(file, "utf8");
  for (const pattern of forbidden) {
    if (pattern.test(content)) failures.push("Forbidden implementation in " + path.relative(root, file));
  }
}

const report = [
  "NEXORAA CLEANSOFT SCAFFOLD VERIFICATION",
  "Status: " + (failures.length ? "FAIL" : "PASS"),
  "Backend services checked: " + backendApps.length,
  "Shared packages checked: " + packages.length,
  "Planning documents checked: " + planningDocuments.length,
  "Phase prompts checked: " + phasePrompts.length,
  "Failures: " + failures.length,
  ...failures.map((failure) => "- " + failure),
  "",
].join("\n");
fs.writeFileSync(path.join(root, "FOUNDATION_VERIFICATION.txt"), report, "utf8");
console.log(report);
if (failures.length) process.exitCode = 1;
