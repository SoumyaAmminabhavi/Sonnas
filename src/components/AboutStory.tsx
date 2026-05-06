import Image from "next/image";

export const AboutStory = () => (
  <section id="about" className="py-24 lg:py-40 bg-cream overflow-hidden">
    <div className="container mx-auto px-6 lg:px-12">
      <div className="flex flex-col lg:flex-row items-center gap-20 lg:gap-32">
        {/* Editorial Image Composition */}
        <div className="w-full lg:w-1/2 relative group">
          <div className="relative z-10 aspect-[4/5] rounded-[3rem] overflow-hidden shadow-premium transition-slow">
            <Image
              src="/sonnas_artisanal_craftsmanship_1778065068457.png"
              alt="Artisanal Craftsmanship"
              fill
              unoptimized
              className="object-cover transition-transform duration-1000 group-hover:scale-105"
            />
          </div>
          {/* Decorative Elements */}
          <div className="absolute -bottom-10 -right-10 w-64 h-64 bg-gold/5 rounded-full blur-3xl -z-0" />
          <div className="absolute -top-10 -left-10 w-48 h-48 border border-gold/20 rounded-[3rem] -z-0" />
          
          <div className="absolute top-12 right-12 z-20 bg-white/40 backdrop-blur-md px-6 py-4 rounded-2xl border border-white/30 hidden md:block animate-fade-in">
             <p className="text-[10px] uppercase tracking-[0.2em] font-bold text-cocoa">Est. 1992</p>
             <p className="font-heading text-lg text-gold">Artisanal Roots</p>
          </div>
        </div>

        {/* Text Content */}
        <div className="w-full lg:w-1/2 flex flex-col items-start">
          <span className="text-gold text-[11px] uppercase tracking-[0.3em] font-bold mb-8 block">Our Heritage</span>
          
          <h2 className="font-heading text-5xl md:text-7xl text-cocoa leading-[1.1] mb-10">
            A Passion for <br />
            <span className="italic text-gold">Pure Artistry</span>
          </h2>
          
          <div className="space-y-8 text-text-secondary text-base md:text-lg leading-[1.8] max-w-xl opacity-90">
            <p>
              SONNA&apos;S PATISSERIE was born from a simple dream: to bring the authentic, soul-warming flavors of a traditional French atelier to the vibrant streets of Bengaluru.
            </p>
            <p>
              Every creation is 100% Eggless and Vegetarian, crafted with an artisan&apos;s heart. We blend classic European techniques with the finest local ingredients to ensure every bite is inclusive, pure, and absolutely divine.
            </p>
          </div>

          <div className="mt-16 pt-8 border-t border-cocoa/10 w-full flex items-center gap-12">
             <div className="flex flex-col">
                <span className="font-heading text-3xl text-gold">100%</span>
                <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted">Vegetarian</span>
             </div>
             <div className="flex flex-col">
                <span className="font-heading text-3xl text-gold">Artisan</span>
                <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted">Handcrafted</span>
             </div>
             <div className="flex flex-col">
                <span className="font-heading text-3xl text-gold">Pure</span>
                <span className="text-[9px] uppercase tracking-[0.2em] font-bold text-text-muted">Ingredients</span>
             </div>
          </div>
        </div>
      </div>
    </div>
  </section>
);
