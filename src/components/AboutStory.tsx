import Image from "next/image";
import Link from "next/link";


export const AboutStory = () => (
  <section id="about" className="py-2xl bg-cream overflow-hidden">
    <div className="container mx-auto px-lg">
      <div className="flex flex-col md:flex-row items-center gap-2xl">
        {/* Images with stylized layout */}
        <div className="w-full md:w-1/2 relative">
          <div className="relative z-10 rounded-lg overflow-hidden shadow-medium transform -rotate-2 hover:rotate-0 transition-default">
            <Image
              src="https://images.unsplash.com/photo-1556910103-1c02745aae4d?q=80&w=1000"
              alt="Artisanal Bakery"
              width={1000}
              height={500}
              className="w-full h-[500px] object-cover"
            />
          </div>
          <div className="absolute -bottom-8 -right-8 w-64 h-64 bg-blush/30 rounded-lg -z-0" />
          <div className="absolute -top-8 -left-8 w-48 h-48 border border-gold/40 rounded-lg -z-0" />
        </div>

        {/* Text Content */}
        <div className="w-full md:w-1/2 space-y-lg">
          <span className="text-gold font-body text-sm uppercase tracking-widest">Since 1992</span>
          <h2 className="text-4xl md:text-5xl font-heading text-text-primary leading-tight">
            Our Story: A Passion for <span className="italic text-rose">Sweetness</span>
          </h2>
          <div className="space-y-md text-text-secondary font-body leading-relaxed text-lg">
            <p>
              SONNA&apos;S PATISSERIE & CAFE was born from a simple dream: to bring the authentic, soul-warming flavors of a traditional French patisserie to the vibrant streets of Bengaluru.
            </p>
            <p>
              Every creation at Sonna&apos;s is 100% Eggless and Vegetarian, crafted with an artisan&apos;s heart. We blend classic French techniques with the finest local ingredients to ensure every bite is inclusive, pure, and absolutely divine.
            </p>
          </div>
          <div className="pt-md">
            <Link 
              href="/about"
              className="text-text-primary font-body border-b-2 border-rose pb-1 hover:text-rose transition-default"
            >
              Discover Our Heritage
            </Link>

          </div>
        </div>
      </div>
    </div>
  </section>
);
