/** One observed frame state consumed directly by every member; never relay through parent layout. */
@Observed
export class BoardMotion {
  ids: string[] = [];
  x: number = 0;
  y: number = 0;
}
