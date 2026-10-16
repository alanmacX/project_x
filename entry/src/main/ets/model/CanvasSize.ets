export const CREATION_DIMENSIONS: string[] = ['4*4', '2*4', '2*2'];
export function creationDimension(value: string): string {
  return CREATION_DIMENSIONS.includes(value) ? value : '4*4';
}
/** Authored defaults; a host rectangle is a separate runtime measurement. */
export function creationAspect(dimension: string): number { return dimension === '2*4' ? 2 : 1; }
