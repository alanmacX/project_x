/** Hardware + active fold form, never a width breakpoint or a device model name.
 * Numeric API values retain API24 compatibility with newer triple-fold states.
 */
export function lockPhonePortrait(deviceType: string, foldable: boolean, status: number = 0, mode: number = 0): boolean {
  if (!foldable) return deviceType === 'phone';
  // Folded arrives before the active display changes; lock without waiting for it.
  if (status === 2) return true;
  // Known expanded forms: ordinary inner, triple full, triple double.
  if (status === 1 || status === 11 || status === 12) return false;
  // Half-folded posture alone does not say which display hosts the app.
  if (mode === 2 || mode === 3) return true;
  if (mode === 1 || mode === 4) return false;
  // Unknown/transitional forms on phones fail safely to portrait.
  return deviceType === 'phone';
}
