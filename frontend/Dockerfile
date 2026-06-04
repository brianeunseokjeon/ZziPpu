# Next.js 16 (dev/preview 용 단순 이미지). 프로덕션 최적화는 standalone 빌드로 후속.
FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev", "--", "--port", "3000", "--hostname", "0.0.0.0"]
