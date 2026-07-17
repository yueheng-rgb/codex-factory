# FACTORY-BUILD-REALWORLD-2-H: Baseline Local Validation Plan

**Date**: 2026-06-27
**Phase**: H — Baseline Local Validation Plan

---

## 1. Environment Detection

| Check | Method |
|-------|--------|
| Python version | `python --version` (requires 3.8+) |
| pip available | `pip --version` |
| Virtual env tool | `python -m venv` |

## 2. Validation Steps

### Step 1: Environment Setup
```bash
cd working-copy
python -m venv venv
venv\Scripts\activate
pip install django django-widget-tweaks openpyxl python-dotenv Pillow
```

### Step 2: Django System Check
```bash
python manage.py check --deploy
```
Expected: No errors; warnings acceptable

### Step 3: Database Migration Check
```bash
python manage.py makemigrations --check --dry-run
```
Expected: "No changes detected"

### Step 4: Migration Execution
```bash
python manage.py migrate
```
Expected: All migrations applied successfully

### Step 5: Seed Data
```bash
python manage.py seed_data
```
Expected: Projects, admin, demo doctor created

### Step 6: Run Tests
```bash
python manage.py test core -v 2
```
Expected: All tests pass

### Step 7: Smoke Test (local runserver)
```bash
# Start server in background, test key endpoints
python manage.py runserver 127.0.0.1:8000 --noreload
# Test: GET / → redirect to login
# Test: POST /login/ with admin/admin123 → 302 success
# Test: GET /admin/ → 200 (admin dashboard)
# Test: GET /admin/doctors/ → 200
# Test: GET /health/ → 200
```

## 3. Boundaries

| Rule | Status |
|------|--------|
| Local-only execution | ✅ |
| No external server access | ✅ |
| No production DB access | ✅ |
| No remote deploy | ✅ |
| Bounded smoke test only | ✅ |

## 4. Phase H Status: COMPLETE
