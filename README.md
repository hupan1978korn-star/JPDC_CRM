# JPDC CRM — Jinxi Seaview City (金禧海景城)

Sales management system for Tower A (841 units) + Tower E (386 units).

## Files

| File | Purpose |
|------|---------|
| `一键更新数据.bat` | Import Excel → databases → push to GitHub |
| `scripts/git-sync.bat` | Push database to GitHub |
| `scripts/git-pull.bat` | Pull database from GitHub (for other machines) |
| `启动后端.bat` | Start FastAPI backend on port 8001 |
| iOS编译指南.md | iOS build instructions |

## Setup (new machine)

1. Install Python 3.9+, Git, GitHub CLI
2. `gh auth login`
3. `git clone <repo-url> JPDC_CRM`
4. `pip install -r backend/requirements.txt`
5. `python backend/db_setup.py` (first time)
6. Run `启动后端.bat`
7. Open mobile app, set server to `http://<your-ip>:8001`

## Database hosted on GitHub

Push to GitHub (after each Excel import):

```
scripts/git-sync.bat
```

Or use the button in the GitHub app / VS Code.

## Components

- backend/ = FastAPI + SQLite
- backend/main.py = API server (dashboard, units, overdue, sold, payments, returned, problems, login)
- backend/db_setup.py = Create tables + import initial data
- backend/import_excel.py = Monthly Excel import engine
- scripts/ = Git push/pull automation (cross-machine sync)

## API

Base URL: http://192.168.8.46:8001

| Endpoint | Description |
|----------|-------------|
| /api/health | Health check |
| /api/dashboard | Dashboard (sold, tower breakdown, KPI) |
| /api/units | Unit list (pagination, filters) |
| /api/units/{id} | Single unit |
| /api/units/inventory | Inventory by tower/type |
| /api/overdue | Overdue warnings |
| /api/sold | Sold clients |
| /api/payments | Payment details |
| /api/payments/summary | Payment summary |
| /api/returned | Returned units |
| /api/problems | Problem units |
| /api/login | JWT login |
| /api/users | User list |
| /api/roles | Role list |

## Version

v2.1 — July 2026
