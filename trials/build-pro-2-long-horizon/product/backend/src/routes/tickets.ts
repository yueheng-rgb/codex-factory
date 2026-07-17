import { Router, Request, Response } from 'express';
import { authenticate, auditLog } from '../middleware/auth';
import * as svc from '../services/tickets';
import * as notif from '../services/notifications';
const router = Router();
router.use(authenticate);
router.get('/project/:projectId', (req, res) => { res.json({ success: true, data: svc.listTickets(req.params.projectId) }); });
router.post('/', (req, res) => {
  try {
    const ticket = svc.createTicket(req.body) as any;
    auditLog(req, 'CREATE', 'ticket', ticket.id);
    res.json({ success: true, data: ticket });
  } catch(e: any) { res.status(400).json({ success: false, error: e.message }); }
});
router.put('/:id', (req, res) => {
  try {
    const ticket = svc.updateTicket(req.params.id, req.body) as any;
    auditLog(req, 'UPDATE', 'ticket', req.params.id);
    if (ticket.assignee_id) notif.createNotification(ticket.assignee_id, 'ticket_update', 'Ticket Updated', `Ticket "${ticket.title}" is now ${ticket.status}`);
    res.json({ success: true, data: ticket });
  } catch(e: any) { res.status(400).json({ success: false, error: e.message }); }
});
export default router;
