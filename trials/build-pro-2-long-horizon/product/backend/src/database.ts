import Database from 'better-sqlite3';
import path from 'path';

const DB_PATH = path.join(__dirname, '..', '..', 'nexusdesk.db');
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

export function initializeDatabase(): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'agent',
      organization_id TEXT, created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS clients (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT, phone TEXT,
      organization_id TEXT NOT NULL, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT,
      status TEXT DEFAULT 'active', organization_id TEXT NOT NULL,
      lead_id TEXT REFERENCES users(id), created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
      status TEXT DEFAULT 'todo', priority TEXT DEFAULT 'medium',
      project_id TEXT REFERENCES projects(id), assignee_id TEXT REFERENCES users(id),
      due_date TEXT, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS tickets (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
      status TEXT DEFAULT 'new', priority TEXT DEFAULT 'medium',
      project_id TEXT REFERENCES projects(id), assignee_id TEXT REFERENCES users(id),
      client_id TEXT REFERENCES clients(id), created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS approvals (
      id TEXT PRIMARY KEY, ticket_id TEXT REFERENCES tickets(id),
      type TEXT NOT NULL, status TEXT DEFAULT 'pending',
      requested_by_id TEXT REFERENCES users(id), approved_by_id TEXT REFERENCES users(id),
      comment TEXT, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS articles (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT,
      category TEXT, author_id TEXT REFERENCES users(id),
      organization_id TEXT, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY, user_id TEXT REFERENCES users(id),
      type TEXT, title TEXT, message TEXT, read INTEGER DEFAULT 0,
      link TEXT, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS audit_log (
      id TEXT PRIMARY KEY, user_id TEXT, action TEXT,
      entity_type TEXT, entity_id TEXT, changes TEXT, created_at TEXT
    );
    CREATE TABLE IF NOT EXISTS automation_rules (
      id TEXT PRIMARY KEY, name TEXT, trigger_event TEXT,
      conditions TEXT, actions TEXT, enabled INTEGER DEFAULT 1,
      organization_id TEXT, created_at TEXT, updated_at TEXT
    );
  `);
}

export default db;
