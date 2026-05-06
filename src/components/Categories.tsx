import Image from "next/image";
import Link from "next/link";
import { categories } from "~/data/landing";

export const Categories = () => (
  <section id="categories" className="py-24 bg-ivory">
    <div className="container mx-auto px-6 lg:px-12">
      <div className="flex flex-col md:flex-row justify-between items-end mb-16 gap-6">
        <div className="max-w-2xl">
          <h2 className="font-heading text-4xl md:text-5xl text-cocoa mb-4">
            Browse by <span className="italic">Category</span>
          </h2>
          <p className="text-[11px] uppercase tracking-[0.2em] font-bold text-text-muted">
            Find your perfect match from our curated selections
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
        {categories.map((category) => (
          <Link
            key={category.id}
            href={`#cakes`}
            className="group relative aspect-[3/4] rounded-3xl overflow-hidden cursor-pointer shadow-premium transition-slow"
          >
            <Image
              src={category.image}
              alt={category.name}
              fill
              unoptimized
              className="object-cover transition-transform duration-[2000ms] group-hover:scale-110"
            />
            {/* Artistic Overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-cocoa/80 via-cocoa/10 to-transparent opacity-80 group-hover:from-gold/80 transition-slow" />

            {/* Content Plate */}
            <div className="absolute bottom-0 left-0 right-0 p-8 transform translate-y-2 group-hover:translate-y-0 transition-slow">
              <div className="flex flex-col items-start gap-2">
                 <span className="text-[9px] uppercase tracking-[0.3em] font-bold text-white/60 mb-1">Collection</span>
                 <h3 className="text-2xl font-heading text-white tracking-wide">
                  {category.name}
                </h3>
                <div className="w-0 group-hover:w-12 h-px bg-white/40 transition-all duration-700 mt-2" />
                <span className="mt-4 text-[10px] uppercase tracking-[0.2em] font-bold text-white opacity-0 group-hover:opacity-100 transition-slow">
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
