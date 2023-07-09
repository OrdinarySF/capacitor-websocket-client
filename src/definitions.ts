export interface WebSocketPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
