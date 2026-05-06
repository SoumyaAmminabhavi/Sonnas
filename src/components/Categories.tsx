import Image from "next/image";
import Link from "next/link";
import { categories } from "~/data/landing";

export const Categories = () => (
  <section id="categories" className="py-24 lg:py-40 bg-ivory">
    <div className="container mx-auto px-8 lg:px-16">
      <div className="flex flex-col md:flex-row justify-between items-end mb-20 gap-8">
        <div className="max-w-4xl">
          <h2 className="font-heading text-5xl md:text-7xl text-cocoa mb-6">
            Browse by <span className="italic">Category</span>
          </h2>
          <p className="text-[12px] uppercase tracking-[0.3em] font-extrabold text-text-muted">
            Find your perfect match from our curated selections
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-12">
        {categories.map((category) => (
          <Link
            key={category.id}
            href={`#cakes`}
            className="group relative aspect-[3/4.5] rounded-[2.5rem] overflow-hidden cursor-pointer shadow-premium transition-slow border border-cocoa/5"
          >
            <Image
              src={category.image}
              alt={category.name}
              fill
              unoptimized
              className="object-cover transition-transform duration-[2s] group-hover:scale-110"
            />
            {/* Artistic Overlay - Reduced opacity and improved gradient */}
            <div className="absolute inset-0 bg-gradient-to-t from-cocoa/90 via-cocoa/20 to-transparent opacity-60 group-hover:opacity-80 group-hover:from-gold/90 transition-slow" />

            {/* Content Plate - Improved contrast and layout */}
            <div className="absolute bottom-0 left-0 right-0 p-10 transform translate-y-4 group-hover:translate-y-0 transition-slow">
              <div className="flex flex-col items-start gap-3">
                 <span className="text-[10px] uppercase tracking-[0.35em] font-bold text-white/80 mb-1">Collection</span>
                 <h3 className="text-3xl font-heading text-white tracking-wide leading-tight drop-shadow-lg">
                  {category.name}
                </h3>
                <div className="w-0 group-hover:w-16 h-[1.5px] bg-white/60 transition-all duration-1000 mt-2" />
                <span className="mt-6 text-[11px] uppercase tracking-[0.3em] font-extrabold text-white border border-white/30 px-6 py-2.5 rounded-full opacity-0 group-hover:opacity-100 transition-slow hover:bg-white hover:text-gold">
                  View Cakes
                </span>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  </section>
);
