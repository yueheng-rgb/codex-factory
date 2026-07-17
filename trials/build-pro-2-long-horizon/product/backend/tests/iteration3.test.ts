import { initializeDatabase } from '../src/database';
import * as articles from '../src/services/articles';
import * as automation from '../src/services/automation';
beforeAll(()=>initializeDatabase());
describe('Knowledge Base',()=>{
  let articleId:string;
  it('create article',()=>{const a=articles.createArticle({title:'How-To',content:'Steps...',category:'guide',authorId:'u1',organizationId:'org1'})as any;expect(a.title).toBe('How-To');articleId=a.id;});
  it('search articles',()=>{const r=articles.searchArticles('org1','How')as any[];expect(r.length).toBeGreaterThanOrEqual(1);});
  it('update article',()=>{const a=articles.updateArticle(articleId,{title:'Updated How-To',content:'New steps',category:'guide'})as any;expect(a.title).toBe('Updated How-To');});
});
describe('Automation Rules',()=>{
  it('create rule',()=>{const r=automation.createRule({name:'Auto-close',triggerEvent:'ticket.resolved',conditions:{days:7},actions:['close_ticket'],organizationId:'org1'})as any;expect(r.name).toBe('Auto-close');});
  it('list rules',()=>{const r=automation.listRules('org1')as any[];expect(r.length).toBeGreaterThanOrEqual(1);});
});
