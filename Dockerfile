FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY app.js .
COPY data.json .

EXPOSE 3000

CMD ["node", "app.js"]
