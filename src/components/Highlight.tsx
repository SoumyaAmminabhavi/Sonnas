import { env } from "~/env";
import Image from "next/image";

export const Highlight = () => (
  <section id="highlight" className="relative py-32 lg:py-48 overflow-hidden bg-ivory">
    {/* Background Imagery */}
    <div className="absolute inset-0 z-0">
      <Image
        src="/sonnas_custom_celebration_1778065092310.png"
        alt="Custom Celebration Atelier"
        fill
        unoptimized
        className="object-cover opacity-25 grayscale-[0.3]"
      />
      <div className="absolute inset-0 bg-gradient-to-b from-ivory via-ivory/20 to-ivory" />
    </div>

    <div className="container mx-auto px-8 lg:px-16 relative z-10">
      <div className="flex flex-col items-center text-center max-w-5xl mx-auto">
        <span className="text-gold text-[12px] uppercase tracking-[0.45em] font-extrabold mb-10 block">Bespoke Creations</span>
        
        {/* Fixed Overlapping Typography - Added better line-height and spacing */}
        <h2 className="font-heading text-6xl md:text-8xl lg:text-[10rem] text-cocoa leading-[0.95] mb-12 [text-wrap:balance]">
          The <span className="italic text-gold drop-shadow-sm">Custom</span> <br className="hidden md:block" />
          Atelier
        </h2>
        
        {/* Widened Text Container for Readability */}
        <p className="text-base md:text-2xl text-text-secondary leading-relaxed mb-16 opacity-90 font-medium tracking-wide max-w-4xl px-4">
          From grand celebrations to intimate moments, our artisans design edible masterpieces that reflect your unique story. Hand-sculpted details, delicate sugar artistry, and flavors that linger in memory.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-8 w-full sm:w-auto">
          <a 
            href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent("Hi! I'd like to design my own cake")}`}
            className="w-full sm:w-auto bg-cocoa text-cream text-[12px] uppercase tracking-[0.25em] font-extrabold py-7 px-16 rounded-full hover:bg-gold transition-slow shadow-premium text-center transform hover:-translate-y-1"
          >
            Design Your Masterpiece
          </a>
          <button className="w-full sm:w-auto border-2 border-cocoa/20 text-cocoa text-[12px] uppercase tracking-[0.25em] font-extrabold py-7 px-16 rounded-full hover:bg-white hover:border-gold hover:text-gold transition-slow text-center bg-white/40 backdrop-blur-md">
            View the Gallery
          </button>
        </div>

        {/* Minimal Stats/Trust - Standardized Grid */}
        <div className="mt-32 grid grid-cols-1 sm:grid-cols-3 gap-16 border-t border-cocoa/10 pt-16 w-full max-w-4xl">
           <div className="flex flex-col items-center">
              <span className="font-heading text-3xl text-cocoa">Infinite</span>
              <span className="text-[11px] uppercase tracking-[0.3em] font-extrabold text-text-muted mt-3">Possibilities</span>
           </div>
           <div className="flex flex-col items-center">
              <span className="font-heading text-3xl text-cocoa">Hand-Drawn</span>
              <span className="text-[11px] uppercase tracking-[0.3em] font-extrabold text-text-muted mt-3">Sketches</span>
           </div>
           <div className="flex flex-col items-center">
              <span className="font-heading text-3xl text-cocoa">Pure</span>
              <span className="text-[11px] uppercase tracking-[0.3em] font-extrabold text-text-muted mt-3">Artistry</span>
           </div>
        </div>
      </div>
    </div>
  </section>
);
