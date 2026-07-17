import { initializeDatabase } from '../src/database';
import * as tickets from '../src/services/tickets';
beforeAll(()=>initializeDatabase());
describe('Ticket Workflow',()=>{
  let ticketId:string;
  it('should create ticket',()=>{const t=tickets.createTicket({title:'Bug',projectId:'tp-1',priority:'high'})as any;expect(t.status).toBe('new');ticketId=t.id;});
  it('new->triaged',()=>{const t=tickets.updateTicket(ticketId,{status:'triaged'})as any;expect(t.status).toBe('triaged');});
  it('triaged->assigned',()=>{const t=tickets.updateTicket(ticketId,{status:'assigned'})as any;expect(t.status).toBe('assigned');});
  it('assigned->waiting_customer',()=>{const t=tickets.updateTicket(ticketId,{status:'waiting_customer'})as any;expect(t.status).toBe('waiting_customer');});
  it('waiting_customer->resolved',()=>{const t=tickets.updateTicket(ticketId,{status:'resolved'})as any;expect(t.status).toBe('resolved');});
  it('resolved->closed',()=>{const t=tickets.updateTicket(ticketId,{status:'closed'})as any;expect(t.status).toBe('closed');});
  it('closed->reopened',()=>{const t=tickets.updateTicket(ticketId,{status:'reopened'})as any;expect(t.status).toBe('reopened');});
  it('should reject invalid transition',()=>{expect(()=>tickets.updateTicket(ticketId,{status:'assigned'})).toThrow();});
});
