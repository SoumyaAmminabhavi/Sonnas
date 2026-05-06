import Link from "next/link";
import Image from "next/image";

export const Hero = () => (
  <section
    id="home"
    className="relative h-screen flex items-center justify-center overflow-hidden bg-cream"
  >
    {/* Background Image */}
    <div className="absolute inset-0 z-0">
      <Image
        src="/sonnas_luxury_hero_1778065050369.png"
        alt="Sonna's Luxury Pâtisserie"
        fill
        className="object-cover object-center scale-105"
        priority
        unoptimized
      />
      {/* Editorial Overlay */}
      <div className="absolute inset-0 bg-gradient-to-r from-cream/60 via-cream/30 to-transparent md:bg-gradient-to-r md:from-cream/80 md:via-cream/40 md:to-transparent" />
      <div className="absolute inset-0 bg-black/5" />
    </div>

    {/* Content */}
    <div className="relative z-10 container mx-auto px-6 lg:px-12">
      <div className="max-w-4xl">
        <div className="inline-flex items-center gap-3 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full border border-white/30 mb-8 animate-fade-in">
           <span className="w-2 h-2 rounded-full bg-gold animate-pulse" />
           <span className="text-[10px] uppercase tracking-[0.2em] font-bold text-cocoa/80">Artisanal & Eggless</span>
        </div>
        
        <h1 className="font-heading text-6xl md:text-8xl lg:text-[10rem] text-cocoa leading-[0.9] mb-8 animate-fade-in [text-wrap:balance]">
          Crafted with <span className="italic text-gold">Love</span>, <br />
          Baked to <span className="text-gold">Perfection</span>
        </h1>
        
        <p className="text-sm md:text-lg text-text-secondary max-w-xl mb-12 leading-relaxed animate-fade-in opacity-90 font-medium tracking-wide">
          Experience the refined elegance of French pâtisserie tradition, where every detail is a delicate dance of flavor and artisanal mastery.
        </p>

        <div className="flex flex-col sm:flex-row items-center gap-6 animate-fade-in">
          <Link
            href="#cakes"
            className="w-full sm:w-auto text-center bg-cocoa text-cream text-[11px] uppercase tracking-[0.2em] font-bold py-5 px-12 rounded-full hover:bg-gold transition-slow shadow-premium"
          >
            Explore Collection
          </Link>
          <Link
            href="#highlight"
            className="w-full sm:w-auto text-center border border-cocoa/20 text-cocoa text-[11px] uppercase tracking-[0.2em] font-bold py-5 px-12 rounded-full hover:bg-ivory transition-slow"
          >
            Custom Atelier
          </Link>
        </div>
      </div>
    </div>

    {/* Scroll Indicator */}
    <div className="absolute bottom-12 left-1/2 -translate-x-1/2 flex flex-col items-center gap-4 opacity-40">
      <span className="text-[9px] uppercase tracking-[0.3em] font-bold text-cocoa">Scroll</span>
      <div className="w-px h-12 bg-gradient-to-b from-cocoa to-transparent" />
    </div>
  </section>
);
