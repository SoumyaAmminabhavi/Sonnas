import Image from "next/image";

export const AboutStory = () => (
  <section id="about" className="py-24 lg:py-48 bg-cream overflow-hidden">
    <div className="container mx-auto px-8 lg:px-16">
      <div className="flex flex-col lg:flex-row items-center gap-24 lg:gap-32">
        {/* Editorial Image Composition */}
        <div className="w-full lg:w-1/2 relative group">
          <div className="relative z-10 aspect-[4/5] rounded-[3rem] overflow-hidden shadow-premium transition-slow border border-cocoa/5">
            <Image
              src="/sonnas_artisanal_craftsmanship_1778065068457.png"
              alt="Artisanal Craftsmanship"
              fill
              unoptimized
              className="object-cover transition-transform duration-[1.5s] group-hover:scale-105"
            />
          </div>
          {/* Decorative Elements - Reduced size and balanced */}
          <div className="absolute -bottom-12 -right-12 w-64 h-64 bg-gold/5 rounded-full blur-3xl -z-0" />
          <div className="absolute -top-12 -left-12 w-56 h-56 border border-gold/15 rounded-[3.5rem] -z-0" />
          
          <div className="absolute top-12 right-12 z-20 bg-white/50 backdrop-blur-md px-8 py-6 rounded-3xl border border-white/40 hidden md:block animate-fade-in shadow-premium">
             <p className="text-[11px] uppercase tracking-[0.25em] font-extrabold text-cocoa mb-1">Est. 1992</p>
             <p className="font-heading text-2xl text-gold">Artisanal Roots</p>
          </div>
        </div>

        {/* Text Content - Widened max-width and improved spacing */}
        <div className="w-full lg:w-1/2 flex flex-col items-start">
          <span className="text-gold text-[12px] uppercase tracking-[0.35em] font-extrabold mb-10 block">Our Heritage</span>
          
          <h2 className="font-heading text-6xl md:text-8xl text-cocoa leading-[1] mb-12">
            A Passion for <br />
            <span className="italic text-gold">Pure Artistry</span>
          </h2>
          
          <div className="space-y-10 text-text-secondary text-base md:text-xl leading-[1.8] max-w-2xl opacity-90 font-medium">
            <p>
              SONNA&apos;S PATISSERIE was born from a simple dream: to bring the authentic, soul-warming flavors of a traditional French atelier to the vibrant streets of Bengaluru.
            </p>
            <p>
              Every creation is 100% Eggless and Vegetarian, crafted with an artisan&apos;s heart. We blend classic European techniques with the finest local ingredients to ensure every bite is inclusive, pure, and absolutely divine.
            </p>
          </div>

          <div className="mt-20 pt-12 border-t border-cocoa/10 w-full flex flex-wrap items-center gap-16">
             <div className="flex flex-col">
                <span className="font-heading text-4xl text-gold">100%</span>
                <span className="text-[10px] uppercase tracking-[0.25em] font-extrabold text-text-muted mt-2">Vegetarian</span>
             </div>
             <div className="flex flex-col">
                <span className="font-heading text-4xl text-gold">Artisan</span>
                <span className="text-[10px] uppercase tracking-[0.25em] font-extrabold text-text-muted mt-2">Handcrafted</span>
             </div>
             <div className="flex flex-col">
                <span className="font-heading text-4xl text-gold">Pure</span>
                <span className="text-[10px] uppercase tracking-[0.25em] font-extrabold text-text-muted mt-2">Ingredients</span>
             </div>
          </div>
        </div>
      </div>
    </div>
  </section>
);
