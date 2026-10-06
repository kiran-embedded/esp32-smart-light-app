import '../core/theme/app_theme.dart';
import '../providers/switch_style_provider.dart';
import '../providers/switch_background_provider.dart';
import '../providers/animation_provider.dart'; // Added

class AdvicePacket {
  final String text;
  final AppThemeMode? theme;
  final SwitchStyleType? style;
  final SwitchBackgroundType? background;
  final AppLaunchAnimation? launchAnimation; // Added
  final UiTransitionAnimation? uiAnimation; // Added

  AdvicePacket({
    required this.text,
    this.theme,
    this.style,
    this.background,
    this.launchAnimation,
    this.uiAnimation,
  });
}

class DesignAdvisorService {
  static AdvicePacket getAdvice({
    required AppThemeMode theme,
    required SwitchStyleType switchStyle,
    required SwitchBackgroundType background,
  }) {
    // 1. Cyber-Void (Amoled + Void + Data Pulse)
    if (theme == AppThemeMode.dark) {
      if (switchStyle != SwitchStyleType.voidAbyss ||
          background != SwitchBackgroundType.cyberGrid) {
        return AdvicePacket(
          text:
              "Let's calibrate for 'Cyber-Void' mode. High-contrast, near-zero lag visuals.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.voidAbyss,
          background: SwitchBackgroundType.cyberGrid,
          launchAnimation: AppLaunchAnimation.cyberGlitch,
          uiAnimation: UiTransitionAnimation.gamingRGB,
        );
      }
    }

    // 2. Quantum Flux (Space + Quantum + Echo)
    if (background == SwitchBackgroundType.starField ||
        theme == AppThemeMode.dark) {
      if (switchStyle != SwitchStyleType.quantumDot) {
        return AdvicePacket(
          text:
              "Quantum state detected. Syncing motion to 'Cosmic Echo' physics.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.quantumDot,
          background: SwitchBackgroundType.starField,
          launchAnimation: AppLaunchAnimation.quantumTunnel,
          uiAnimation: UiTransitionAnimation.cosmicEcho,
        );
      }
    }

    // 3. Liquid Crystal (Pure Gold + Prism)
    if (theme == AppThemeMode.dark) {
      if (switchStyle != SwitchStyleType.crystalPrism) {
        return AdvicePacket(
          text:
              "Refining 'Golden Crystal' aesthetics. Smooth luxury transitions incoming.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.crystalPrism,
          background: SwitchBackgroundType.glassPrism,
          launchAnimation: AppLaunchAnimation.glassDrop,
          uiAnimation: UiTransitionAnimation.iosExactSlide,
        );
      }
    }

    // 4. Holographic OS (Glass + Hologram)
    if (switchStyle == SwitchStyleType.holographic) {
      if (background != SwitchBackgroundType.liquidPlasma) {
        return AdvicePacket(
          text:
              "Holographic projection needs a fluid plasma base for stability.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.holographic,
          background: SwitchBackgroundType.liquidPlasma,
          launchAnimation: AppLaunchAnimation.hologramRise,
          uiAnimation: UiTransitionAnimation.liquidMorph,
        );
      }
    }

    // 5. Matrix / Kali (DevOps Mode)
    if (background == SwitchBackgroundType.dataStream ||
        theme == AppThemeMode.dark) {
      if (switchStyle != SwitchStyleType.realistic) {
        return AdvicePacket(
          text: "Enabling 'Root Terminal' mode. Matrix flux activated.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.realistic,
          background: SwitchBackgroundType.dataStream,
          launchAnimation: AppLaunchAnimation.bladeRunner,
          uiAnimation: UiTransitionAnimation.matrixRain,
        );
      }
    }

    // 6. Bio-Organic (Nature + Organic)
    if (switchStyle == SwitchStyleType.bioOrganic) {
      if (theme != AppThemeMode.dark) {
        return AdvicePacket(
          text:
              "Synchronizing with organic rhythms. Soft aura transitions enabled.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.bioOrganic,
          background: SwitchBackgroundType.auroraBorealis,
          launchAnimation: AppLaunchAnimation.fluidWave,
          uiAnimation: UiTransitionAnimation.softAura,
        );
      }
    }

    // 7. Blood Moon (Vampire + Pulse)
    if (theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.fireEmbers) {
        return AdvicePacket(
          text: "The Crimson Moon rises. Activating high-energy pulse physics.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.cosmicPulse,
          background: SwitchBackgroundType.fireEmbers,
          launchAnimation: AppLaunchAnimation.cinematicFade,
          uiAnimation: UiTransitionAnimation.prismShatter,
        );
      }
    }

    // 8. Cyber-Neon (Tokyo + RGB)
    if (theme == AppThemeMode.dark || theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.neonBorder) {
        return AdvicePacket(
          text: "Tokyo nights require 'Neon Border' architecture.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.neonGlass,
          background: SwitchBackgroundType.neonBorder,
          launchAnimation: AppLaunchAnimation.neonPulse,
          uiAnimation: UiTransitionAnimation.gamingRGB,
        );
      }
    }

    // 9. Retro Synth (Vaporwave)
    if (theme == AppThemeMode.dark || theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.retroSynth) {
        return AdvicePacket(
          text: "Establishing 'Retro-Synth' uplink. Nostalgia drive online.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.retroVapor,
          background: SwitchBackgroundType.retroSynth,
          launchAnimation: AppLaunchAnimation.centerBurst,
          uiAnimation: UiTransitionAnimation.magneticPull,
        );
      }
    }

    // 10. Minimalist (Pure Dark)
    if (theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.defaultBlack) {
        return AdvicePacket(
          text:
              "Resetting to 'Absolute Zero' minimalism. Maximum latency focus.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.modern,
          background: SwitchBackgroundType.defaultBlack,
          launchAnimation: AppLaunchAnimation.iPhoneBlend,
          uiAnimation: UiTransitionAnimation.zeroLatency,
        );
      }
    }

    // 11. Solar Flare
    if (switchStyle == SwitchStyleType.solarFlare ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.solarFlare ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Solar activity at peak levels. Synchronizing corona pulses.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.solarFlare,
          background: SwitchBackgroundType.solarFlare,
          launchAnimation: AppLaunchAnimation.hologramRise,
          uiAnimation: UiTransitionAnimation.softAura,
        );
      }
    }

    // 12. Electric Tundra
    if (switchStyle == SwitchStyleType.electricTundra ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.electricTundra ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text:
              "Zero-degree conductivity established. Activating arctic surge.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.electricTundra,
          background: SwitchBackgroundType.electricTundra,
          launchAnimation: AppLaunchAnimation.cyberGlitch,
          uiAnimation: UiTransitionAnimation.zeroLatency,
        );
      }
    }

    // 13. Nano Catalyst
    if (switchStyle == SwitchStyleType.nanoCatalyst ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.nanoCatalyst ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Nano-assembly in progress. Optimizing hexagonal grid.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.nanoCatalyst,
          background: SwitchBackgroundType.nanoCatalyst,
          launchAnimation: AppLaunchAnimation.quantumTunnel,
          uiAnimation: UiTransitionAnimation.matrixRain,
        );
      }
    }

    // 14. Phantom Velvet
    if (switchStyle == SwitchStyleType.phantomVelvet ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.phantomVelvet ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Ghost in the machine detected. Enabling velvet smoothness.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.phantomVelvet,
          background: SwitchBackgroundType.phantomVelvet,
          launchAnimation: AppLaunchAnimation.cinematicFade,
          uiAnimation: UiTransitionAnimation.softAura,
        );
      }
    }

    // 15. Prism Fractal
    if (switchStyle == SwitchStyleType.prismFractal ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.prismFractal ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Refractive index out of bounds. Correcting light-paths.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.prismFractal,
          background: SwitchBackgroundType.prismFractal,
          launchAnimation: AppLaunchAnimation.glassDrop,
          uiAnimation: UiTransitionAnimation.prismShatter,
        );
      }
    }

    // 16. Magma Core
    if (switchStyle == SwitchStyleType.magmaCore ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.magmaCore ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Tectonic shift imminent. Increasing thermal viscosity.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.magmaCore,
          background: SwitchBackgroundType.magmaCore,
          launchAnimation: AppLaunchAnimation.neonPulse,
          uiAnimation: UiTransitionAnimation.gamingRGB,
        );
      }
    }

    // 17. Cyber Bloom
    if (switchStyle == SwitchStyleType.cyberBloom ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.cyberBloom ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Bio-luminesence thriving. Syncing to photosynthetic cycles.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.cyberBloom,
          background: SwitchBackgroundType.cyberBloom,
          launchAnimation: AppLaunchAnimation.fluidWave,
          uiAnimation: UiTransitionAnimation.softAura,
        );
      }
    }

    // 18. Void Rift (Legacy support mapped to Amoled)
    if (switchStyle == SwitchStyleType.voidRift) {
      if (background != SwitchBackgroundType.voidRift ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Singularity event confirmed. Compressing UI gravity.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.voidRift,
          background: SwitchBackgroundType.voidRift,
          launchAnimation: AppLaunchAnimation.quantumTunnel,
          uiAnimation: UiTransitionAnimation.zeroLatency,
        );
      }
    }

    // 19. Starlight Echo
    if (switchStyle == SwitchStyleType.starlightEcho ||
        theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.starlightEcho ||
          theme != AppThemeMode.dark) {
        return AdvicePacket(
          text: "Galactic signal locked. Transmitting through the void.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.starlightEcho,
          background: SwitchBackgroundType.starlightEcho,
          launchAnimation: AppLaunchAnimation.centerBurst,
          uiAnimation: UiTransitionAnimation.cosmicEcho,
        );
      }
    }

    // 20. Platinum Blue
    if (theme == AppThemeMode.dark) {
      if (background != SwitchBackgroundType.aeroStream) {
        return AdvicePacket(
          text: "Laminar flow achieved. Streamlining aerodynamic curves.",
          theme: AppThemeMode.dark,
          style: SwitchStyleType.aeroStream,
          background: SwitchBackgroundType.aeroStream,
          launchAnimation: AppLaunchAnimation.iPhoneBlend,
          uiAnimation: UiTransitionAnimation.iosExactSlide,
        );
      }
    }

    // Random Tips / Fallback
    final randomTips = [
      AdvicePacket(
        text: "Try switching to 'Kali' theme for a dev-heavy aesthetic.",
        theme: AppThemeMode.dark,
        style: SwitchStyleType.realistic,
        background: SwitchBackgroundType.dataStream,
        launchAnimation: AppLaunchAnimation.bladeRunner,
        uiAnimation: UiTransitionAnimation.matrixRain,
      ),
      AdvicePacket(
        text: "Feeling nostalgic? 'Retro Synth' is a radical choice.",
        theme: AppThemeMode.dark,
        style: SwitchStyleType.retroVapor,
        background: SwitchBackgroundType.retroSynth,
      ),
      AdvicePacket(
        text: "Neural nodes link up best with 'Neon Tokyo' themes.",
        theme: AppThemeMode.dark,
        background: SwitchBackgroundType.neuralNodes,
      ),
      AdvicePacket(text: "Double-tap the Robo for a fresh UI analysis scan."),
      AdvicePacket(
        text:
            "Enable 'Haptic Feedback' in sensory settings for a premium feel.",
      ),
    ];

    return randomTips[DateTime.now().second % randomTips.length];
  }
}
