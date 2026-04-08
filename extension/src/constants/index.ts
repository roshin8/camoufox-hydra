/** Extension ID for policies.json and internal references */
export const EXTENSION_ID = 'hydra-shield@camoufox-hydra';

/** Message types for inter-component communication */
export const MSG = {
  HYDRA_ACTIVE: 'HYDRA_ACTIVE',
  FINGERPRINT_ACCESS: 'HYDRA_FINGERPRINT_ACCESS',
  GET_STATUS: 'HYDRA_GET_STATUS',
  STATUS: 'HYDRA_STATUS',
  GET_SETTINGS: 'HYDRA_GET_SETTINGS',
  UPDATE_SETTINGS: 'HYDRA_UPDATE_SETTINGS',
  ROTATE_PROFILE: 'HYDRA_ROTATE_PROFILE',
} as const;

/** Storage keys */
export const STORAGE_KEYS = {
  CONTAINER_ENTROPY: 'containerEntropy',
  CONTAINER_PROFILES: 'containerProfiles',
  GLOBAL_SETTINGS: 'globalSettings',
  DOMAIN_RULES: 'domainRules',
  STATISTICS: 'statistics',
} as const;

/** Default spoofer settings — everything enabled */
export const DEFAULT_SETTINGS = {
  graphics: { canvas: 'noise' as const, webgl: 'noise' as const },
  audio: { context: 'noise' as const },
  navigator: {
    userAgent: 'spoof' as const,
    platform: 'spoof' as const,
    hardwareConcurrency: 'spoof' as const,
  },
  hardware: { screen: 'spoof' as const },
  fonts: { enumeration: 'filter' as const, metrics: 'noise' as const },
  network: { webrtc: 'spoof' as const },
  timing: { timezone: 'spoof' as const },
};
