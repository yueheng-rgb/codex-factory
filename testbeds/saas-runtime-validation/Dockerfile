# Production-Like Dockerfile for SaaS Runtime Validation
# NOT for production deployment — staging/validation only
FROM node:22-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npm run build 2>/dev/null || true

EXPOSE 3100
HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('http').get('http://localhost:3100/health',r=>{process.exit(r.statusCode===200?0:1)})"

CMD ["node","--import","tsx","src/server.ts"]
