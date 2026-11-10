import path from 'node:path'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// A API (Open Liberty) corre em http://localhost:9080. O proxy põe o frontend e a API na mesma origem,
// para o cookie de renovação (HttpOnly; SameSite=Strict) funcionar sem CORS.
const API = process.env.API_URL ?? 'http://localhost:9080'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { '@': path.resolve(__dirname, './src') } },
  server: { port: 5173, proxy: { '/v1': API, '/health': API } },
  preview: { port: 4173, cors: true, proxy: { '/v1': API, '/health': API } },
})
