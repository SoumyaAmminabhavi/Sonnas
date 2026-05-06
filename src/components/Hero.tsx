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
      {/* Refined Editorial Overlay */}
      <div className="absolute inset-0 bg-gradient-to-r from-cream/70 via-cream/40 to-transparent md:from-cream/85 md:via-cream/45 md:to-transparent" />
      <div className="absolute inset-0 bg-black/[0.02]" />
    </div>

    {/* Content */}
    <div className="relative z-10 container mx-auto px-8 lg:px-16">
      <div className="max-w-5xl">
        <div className="inline-flex items-center gap-3 bg-white/30 backdrop-blur-md px-5 py-2.5 rounded-full border border-white/40 mb-10 animate-fade-in shadow-soft">
           <span className="w-2.5 h-2.5 rounded-full bg-gold animate-pulse" />
           <span className="text-[11px] uppercase tracking-[0.25em] font-extrabold text-cocoa">Artisanal & Eggless</span>
        </div>
        
        <h1 className="font-heading text-6xl md:text-8xl lg:text-[9.5rem] text-cocoa leading-[0.85] mb-10 animate-fade-in [text-wrap:balance]">
          Crafted with <span className="italic text-gold drop-shadow-sm">Love</span>, <br />
          Baked to <span className="text-gold drop-shadow-sm">Perfection</span>
        </h1>
        
        <p className="text-base md:text-xl text-text-secondary max-w-2xl mb-14 leading-relaxed animate-fade-in opacity-90 font-medium tracking-wide">
          Experience the refined elegance of French pâtisserie tradition, where every detail is a delicate dance of flavor and artisanal mastery.
        </p>

        <div className="flex flex-col sm:flex-row items-center gap-6 animate-fade-in">
          <Link
            href="#cakes"
            className="w-full sm:w-auto text-center bg-cocoa text-cream text-[12px] uppercase tracking-[0.25em] font-extrabold py-6 px-14 rounded-full hover:bg-gold transition-slow shadow-premium transform hover:-translate-y-1"
          >
            Explore Collection
          </Link>
          <Link
            href="#highlight"
            className="w-full sm:w-auto text-center border-2 border-cocoa/20 text-cocoa text-[12px] uppercase tracking-[0.25em] font-extrabold py-6 px-14 rounded-full hover:bg-white hover:border-gold hover:text-gold transition-slow bg-white/20 backdrop-blur-sm"
          >
            Custom Atelier
          </Link>
        </div>
      </div>
    </div>

    {/* Scroll Indicator */}
    <div className="absolute bottom-12 left-1/2 -translate-x-1/2 flex flex-col items-center gap-5 opacity-50">
      <span className="text-[10px] uppercase tracking-[0.4em] font-extrabold text-cocoa">Explore</span>
      <div className="w-px h-16 bg-gradient-to-b from-cocoa via-gold/50 to-transparent" />
    </div>
  </section>
);
