import db from '../database';
import { v4 as uuid } from 'uuid';
export function listArticles(orgId: string) { return db.prepare('SELECT * FROM articles WHERE organization_id = ? ORDER BY created_at DESC').all(orgId); }
export function getArticle(id: string) { return db.prepare('SELECT * FROM articles WHERE id = ?').get(id); }
export function createArticle(data: any) {
  const id = uuid();
  db.prepare('INSERT INTO articles (id,title,content,category,author_id,organization_id,created_at,updated_at) VALUES (?,?,?,?,?,?,datetime(\'now\'),datetime(\'now\'))')
    .run(id, data.title, data.content, data.category||'general', data.authorId, data.organizationId);
  return getArticle(id);
}
export function updateArticle(id: string, data: any) {
  db.prepare('UPDATE articles SET title=?,content=?,category=?,updated_at=datetime(\'now\') WHERE id=?')
    .run(data.title, data.content, data.category, id);
  return getArticle(id);
}
export function searchArticles(orgId: string, query: string) {
  return db.prepare("SELECT * FROM articles WHERE organization_id = ? AND (title LIKE ? OR content LIKE ?)").all(orgId, `%${query}%`, `%${query}%`);
}
