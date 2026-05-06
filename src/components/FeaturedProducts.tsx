"use client";

import Image from "next/image";
import Link from "next/link";
import { api } from "~/trpc/react";
import { env } from "~/env";

export const FeaturedProducts = () => {
  const { data: cakes, isLoading } = api.cake.getAll.useQuery();

  return (
    <section id="cakes" className="py-24 lg:py-36 bg-cream">
      <div className="container mx-auto px-8 lg:px-16">
        {/* Section Header */}
        <div className="max-w-4xl mb-24">
          <h2 className="font-heading text-5xl md:text-7xl text-cocoa mb-8">
            The <span className="italic">Collection</span>
          </h2>
          <p className="text-sm md:text-base text-text-secondary leading-relaxed max-w-2xl opacity-90 uppercase tracking-[0.25em] font-extrabold">
            Explore our handcrafted signature delights, created daily with the finest seasonal ingredients.
          </p>
        </div>

        {/* Product Grid - Improved gap and layout */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-16 lg:gap-20">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="flex flex-col gap-8 animate-pulse">
                <div className="aspect-[4/5] bg-ivory rounded-[2.5rem]" />
                <div className="h-8 bg-ivory w-2/3 rounded-full" />
                <div className="h-5 bg-ivory w-1/3 rounded-full" />
              </div>
            ))
          ) : (
            cakes?.slice(0, 6).map((cake) => (
              <div
                key={cake.id}
                className="group flex flex-col cursor-pointer"
              >
                {/* Image Container - Increased border radius and shadow */}
                <div className="relative aspect-[4/5] overflow-hidden rounded-[2.5rem] mb-10 shadow-premium transition-slow bg-ivory border border-cocoa/5">
                  <Image
                    src={cake.image}
                    alt={cake.name}
                    fill
                    unoptimized
                    className="object-cover transition-transform duration-[1.5s] group-hover:scale-110"
                  />
                  {/* Refined Overlay */}
                  <div className="absolute inset-0 bg-cocoa/10 opacity-0 group-hover:opacity-100 transition-slow" />
                  
                  {/* Quick Action Button - More prominent */}
                  <div className="absolute bottom-10 left-1/2 -translate-x-1/2 translate-y-6 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-700">
                    <a
                      href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent(`Hi! I'd like to order: ${cake.name}`)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-white text-cocoa text-[11px] uppercase tracking-[0.25em] font-extrabold px-10 py-5 rounded-full shadow-2xl hover:bg-gold hover:text-white transition-slow border border-cocoa/5"
                    >
                      Pre-Order
                    </a>
                  </div>
                </div>

                {/* Product Info - Improved alignment and spacing */}
                <div className="flex flex-col items-start px-4">
                  <div className="flex justify-between items-start w-full mb-3 gap-4">
                    <h3 className="font-heading text-2xl md:text-3xl text-cocoa group-hover:text-gold transition-colors leading-tight">
                      {cake.name}
                    </h3>
                    <span className="font-heading text-xl text-gold mt-1 shrink-0">
                      {cake.options?.[0]?.price ?? "—"}
                    </span>
                  </div>
                  
                  <div className="flex items-center gap-3 mb-6">
                    <span className="text-[10px] uppercase tracking-[0.2em] font-extrabold text-white bg-gold/80 px-2.5 py-1 rounded-md">
                      {cake.category.split(' ')[0]}
                    </span>
                    <span className="text-[10px] uppercase tracking-[0.2em] font-extrabold text-text-muted">
                      &middot; {cake.options?.[0]?.size}
                    </span>
                  </div>

                  {cake.description && (
                    <p className="text-sm md:text-base text-text-secondary leading-relaxed opacity-80 mb-6 max-w-[90%] font-medium">
                      {cake.description}
                    </p>
                  )}
                  
                  <div className="h-[1.5px] w-0 bg-gold/30 transition-all duration-1000 group-hover:w-full" />
                </div>
              </div>
            ))
          )}
        </div>

        {/* View All CTA - Standardized spacing */}
        <div className="mt-32 text-center">
          <Link
            href="#footer"
            className="inline-flex items-center gap-6 text-cocoa group"
          >
            <span className="text-[12px] uppercase tracking-[0.35em] font-extrabold border-b-2 border-cocoa/10 py-3 group-hover:text-gold group-hover:border-gold transition-slow">
              Discover the full menu
            </span>
            <span className="text-2xl transition-transform group-hover:translate-x-3 transition-slow">→</span>
          </Link>
        </div>
      </div>
    </section>
  );
};
