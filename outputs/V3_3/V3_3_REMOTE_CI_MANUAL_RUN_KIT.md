# V3.3 — Remote CI Manual Run Kit

## Purpose

This kit explains how to manually run the Codex Factory CI workflow on GitHub Actions
and provide the resulting artifact for remote verification.

**Codex does NOT need your GitHub token. You do everything manually in the browser.**

---

## Step 1: Push the Workflow to Your Repo

```bash
git add .github/workflows/codex-factory-ci.yml
git commit -m "Add Codex Factory CI workflow"
git push origin main
```

If you're using a fork, push to your fork's default branch.

---

## Step 2: Trigger Workflow on GitHub

1. Go to your repo on GitHub: `https://github.com/<your-org>/<your-repo>`
2. Click **Actions** tab
3. In the left sidebar, click **Codex Factory CI**
4. Click the **Run workflow** dropdown
5. Select a **testbed** from the dropdown (e.g., `products-api`)
6. Click **Run workflow** (green button)

---

## Step 3: Wait for Completion

- The workflow runs 3 jobs: snapshot-verify → regression → frozen-trunk-check
- Wait for all jobs to show green ✅
- This typically takes 1-3 minutes

---

## Step 4: Download Artifact

1. Click the completed workflow run
2. Scroll to the **Artifacts** section at the bottom
3. Click `factory-artifacts-<testbed>` to download the ZIP
4. Save it locally

---

## Step 5: Place Artifact for Verification

Copy the downloaded ZIP to:

```
C:\Codex_App_Factory\artifacts\remote\<your-run-id>\artifact.zip
```

Create the directory if it doesn't exist. Use any run ID you like (e.g., `gh-run-001`).

---

## Step 6: Run Remote Artifact Verifier

```powershell
cd C:\Codex_App_Factory
powershell -File runtime/remote-artifact-verifier.ps1 -Action verify -RunId "gh-run-001"
```

If verification passes, `final_status` will be `REMOTE_ARTIFACT_VERIFIED`.

---

## CRITICAL: What You CANNOT Claim

- ❌ Do NOT claim REMOTE_RUN_VERIFIED without a real artifact ZIP that passes verification
- ❌ Do NOT claim production deployment
- ❌ Do NOT fake artifact contents
- ❌ Local template files are NOT remote artifacts
- ❌ The workflow template itself is NOT a verified run

## Status Without Real Artifact

Until you complete these steps and run the verifier, the highest CI status is:
**REMOTE_RUN_REQUIRED** (or TEMPLATE_READY)