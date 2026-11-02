FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY worker.js ./
ENV NODE_ENV=production
USER node
CMD ["node", "worker.js"]
