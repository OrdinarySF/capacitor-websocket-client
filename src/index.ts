import { registerPlugin } from '@capacitor/core';

import type { WebSocketPlugin } from './definitions';

const WebSocket = registerPlugin<WebSocketPlugin>('WebSocket', {
  web: () => import('./web').then(m => new m.WebSocketWeb()),
});

export * from './definitions';
export { WebSocket };
