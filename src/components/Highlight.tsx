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
        className="object-cover opacity-30 grayscale-[0.5]"
      />
      <div className="absolute inset-0 bg-gradient-to-b from-ivory via-transparent to-ivory" />
    </div>

    <div className="container mx-auto px-6 lg:px-12 relative z-10">
      <div className="flex flex-col items-center text-center max-w-4xl mx-auto">
        <span className="text-gold text-[11px] uppercase tracking-[0.4em] font-bold mb-8 block">Bespoke Creations</span>
        
        <h2 className="font-heading text-5xl md:text-8xl text-cocoa leading-[1] mb-10">
          The <span className="italic text-gold">Custom</span> <br />
          Atelier
        </h2>
        
        <p className="text-base md:text-xl text-text-secondary leading-relaxed mb-16 opacity-80 font-medium tracking-wide max-w-2xl">
          From grand celebrations to intimate moments, our artisans design edible masterpieces that reflect your unique story. Hand-sculpted details, delicate sugar artistry, and flavors that linger in memory.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-8 w-full sm:w-auto">
          <a 
            href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent("Hi! I'd like to design my own cake")}`}
            className="w-full sm:w-auto bg-cocoa text-cream text-[11px] uppercase tracking-[0.2em] font-bold py-6 px-16 rounded-full hover:bg-gold transition-slow shadow-premium text-center"
          >
            Design Your Masterpiece
          </a>
          <button className="w-full sm:w-auto border border-cocoa/20 text-cocoa text-[11px] uppercase tracking-[0.2em] font-bold py-6 px-16 rounded-full hover:bg-white transition-slow text-center bg-white/40 backdrop-blur-sm">
            View the Gallery
          </button>
        </div>

        {/* Minimal Stats/Trust */}
        <div className="mt-24 grid grid-cols-2 md:grid-cols-3 gap-12 border-t border-cocoa/5 pt-12 w-full max-w-2xl">
           <div className="flex flex-col items-center">
              <span className="font-heading text-2xl text-cocoa">Infinite</span>
              <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted mt-2">Possibilities</span>
           </div>
           <div className="flex flex-col items-center">
              <span className="font-heading text-2xl text-cocoa">Hand-Drawn</span>
              <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted mt-2">Sketches</span>
           </div>
           <div className="flex flex-col items-center col-span-2 md:col-span-1">
              <span className="font-heading text-2xl text-cocoa">Pure</span>
              <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted mt-2">Artistry</span>
           </div>
        </div>
      </div>
    </div>
  </section>
);
