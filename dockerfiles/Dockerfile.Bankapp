# Dockerfile
FROM node:14

WORKDIR /app

COPY frontend frontend
COPY backend backend

WORKDIR /app/backend
RUN npm install

EXPOSE 3000

CMD ["node", "server.js"]
