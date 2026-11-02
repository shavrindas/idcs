// import { defineConfig } from 'vite'
// import react from '@vitejs/plugin-react'

// // https://vite.dev/config/
// export default defineConfig({
//   plugins: [react()],
// })

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: '/webui/',
  server: {
    host: '0.0.0.0',
    port: 5173,
    allowedHosts: true, // 모든 호스트 헤더 허용
    // 빌드해서 올리면 백엔드가 /webui 로 같이 서빙하므로 /api 가 그대로 통한다.
    // 하지만 npm run dev 는 5173 에서 따로 돌아 /api 를 받아 줄 사람이 없다.
    // 개발 중에만 중앙 노드로 넘겨 준다 — 빌드 결과물에는 영향이 없다.
    proxy: {
      // ws: the overview page's live feed is a WebSocket under /api as well.
      '/api': { target: 'http://127.0.0.1:8900', changeOrigin: true, ws: true },
    },
  },
  plugins: [react()],
})


