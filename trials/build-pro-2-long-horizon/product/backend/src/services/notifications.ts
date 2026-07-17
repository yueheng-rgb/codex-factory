import db from '../database';
import { v4 as uuid } from 'uuid';
export function createNotification(userId: string, type: string, title: string, message: string, link?: string) {
  const id = uuid();
  db.prepare('INSERT INTO notifications (id,user_id,type,title,message,link,created_at) VALUES (?,?,?,?,?,?,datetime(\'now\'))')
    .run(id, userId, type, title, message, link||null);
}
export function listNotifications(userId: string) { return db.prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC').all(userId); }
export function markRead(id: string) { db.prepare('UPDATE notifications SET read = 1 WHERE id = ?').run(id); }
export function unreadCount(userId: string) { return (db.prepare('SELECT COUNT(*) as c FROM notifications WHERE user_id = ? AND read = 0').get(userId) as any).c; }
