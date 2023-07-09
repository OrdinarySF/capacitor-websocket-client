import { WebPlugin } from '@capacitor/core';

import type { WebSocketPlugin } from './definitions';

export class WebSocketWeb extends WebPlugin implements WebSocketPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
