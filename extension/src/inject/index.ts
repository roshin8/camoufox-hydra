/**
 * Inject entry point — MAIN world, document_start.
 *
 * Reads __HYDRA__ config injected by background, calls the Camoufox bridge
 * to configure C++ spoofing, then cleans up.
 */

import { configureCamoufoxSpoofing } from './camoufox-bridge';
import { initFingerprintMonitor } from './monitor/fingerprint-monitor';
import { generateFallbackSeed } from '@/lib/crypto';
import { DEFAULT_SETTINGS } from '@/constants';
import type { CamoufoxWindow, HydraConfig } from '@/types';
import { DEFAULT_PROFILE } from '@/lib/profiles/default';

const win = window as unknown as CamoufoxWindow;

(async () => {
  const domain = window.location.hostname;

  // Read config injected by background (via config-injector.ts)
  const config: HydraConfig | undefined = win.__HYDRA__;
  delete win.__HYDRA__; // Prevent page access

  if (config) {
    await configureCamoufoxSpoofing(
      config.seed,
      config.domain,
      config.profile,
      config.settings
    );
  } else {
    // Fallback: domain-only seed (no container context available)
    const fallbackSeed = await generateFallbackSeed(domain);
    await configureCamoufoxSpoofing(
      fallbackSeed,
      domain,
      DEFAULT_PROFILE,
      DEFAULT_SETTINGS
    );
  }

  // Monitor fingerprint access attempts (for popup display)
  initFingerprintMonitor();

  // Notify content script that spoofing is active
  window.postMessage({ type: 'HYDRA_ACTIVE', domain }, '*');
})();
