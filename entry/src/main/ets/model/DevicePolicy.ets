/** Use hardware capability, not current width: a folded phone must remain adaptable. */
export function lockPhonePortrait(deviceType: string, foldable: boolean): boolean {
  return deviceType === 'phone' && !foldable;
}
