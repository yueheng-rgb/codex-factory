# NexusDesk Enterprise Lite

Trial product for FACTORY-BUILD-PRO-2: Long-Horizon Native Build Pro Trial.

## Tech Stack
- Backend: Node.js + Express + TypeScript + SQLite (better-sqlite3)
- Frontend: React + TypeScript + Vite
- Auth: bcrypt + JWT
- API: RESTful JSON

## Quick Start
```bash
# Backend
cd backend && npm install && npm run dev

# Frontend
cd frontend && npm install && npm run dev
```

## API Endpoints
- POST /api/auth/register
- POST /api/auth/login
- GET /api/clients
- POST /api/clients
- PUT /api/clients/:id
- DELETE /api/clients/:id
- GET /api/projects
- POST /api/projects
- PUT /api/projects/:id
- GET /api/tasks/project/:projectId
- POST /api/tasks
- PUT /api/tasks/:id
