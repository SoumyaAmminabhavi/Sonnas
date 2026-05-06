"use client";

import Image from "next/image";
import Link from "next/link";
import { api } from "~/trpc/react";
import { env } from "~/env";

export const FeaturedProducts = () => {
  const { data: cakes, isLoading } = api.cake.getAll.useQuery();

  return (
    <section id="cakes" className="py-24 lg:py-32 bg-cream">
      <div className="container mx-auto px-6 lg:px-12">
        {/* Section Header */}
        <div className="max-w-3xl mb-20">
          <h2 className="font-heading text-4xl md:text-6xl text-cocoa mb-6">
            The <span className="italic">Collection</span>
          </h2>
          <p className="text-sm md:text-base text-text-secondary leading-relaxed max-w-xl opacity-80 uppercase tracking-widest font-bold">
            Explore our handcrafted signature delights, created daily with the finest seasonal ingredients.
          </p>
        </div>

        {/* Product Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-12 lg:gap-16">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="flex flex-col gap-6 animate-pulse">
                <div className="aspect-[4/5] bg-ivory rounded-2xl" />
                <div className="h-6 bg-ivory w-2/3 rounded-full" />
                <div className="h-4 bg-ivory w-1/3 rounded-full" />
              </div>
            ))
          ) : (
            cakes?.slice(0, 6).map((cake) => (
              <div
                key={cake.id}
                className="group flex flex-col cursor-pointer"
              >
                {/* Image Container */}
                <div className="relative aspect-[4/5] overflow-hidden rounded-2xl mb-8 luxury-card">
                  <Image
                    src={cake.image}
                    alt={cake.name}
                    fill
                    unoptimized
                    className="object-cover transition-transform duration-1000 group-hover:scale-105"
                  />
                  {/* Subtle Overlay */}
                  <div className="absolute inset-0 bg-cocoa/5 opacity-0 group-hover:opacity-100 transition-slow" />
                  
                  {/* Quick Action Button */}
                  <div className="absolute bottom-6 left-1/2 -translate-x-1/2 translate-y-4 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500">
                    <a
                      href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent(`Hi! I'd like to order: ${cake.name}`)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="bg-white/90 backdrop-blur-md text-cocoa text-[10px] uppercase tracking-widest font-bold px-8 py-3 rounded-full shadow-lg hover:bg-gold hover:text-white transition-slow"
                    >
                      Pre-Order
                    </a>
                  </div>
                </div>

                {/* Product Info */}
                <div className="flex flex-col items-start px-2">
                  <div className="flex justify-between items-start w-full mb-2">
                    <h3 className="font-heading text-xl md:text-2xl text-cocoa group-hover:text-gold transition-colors">
                      {cake.name}
                    </h3>
                    <span className="font-body text-sm text-gold font-bold">
                      {cake.options?.[0]?.price ?? "Price on Request"}
                    </span>
                  </div>
                  <p className="text-[11px] uppercase tracking-widest text-text-muted font-bold mb-4">
                    {cake.category} &middot; {cake.options?.[0]?.size}
                  </p>
                  {cake.description && (
                    <p className="text-sm text-text-secondary leading-relaxed opacity-70 mb-4 line-clamp-2">
                      {cake.description}
                    </p>
                  )}
                  <div className="h-px w-0 bg-gold transition-all duration-700 group-hover:w-full opacity-30" />
                </div>
              </div>
            ))
          )}
        </div>

        {/* View All CTA */}
        <div className="mt-24 text-center">
          <Link
            href="#footer"
            className="inline-flex items-center gap-4 text-cocoa group"
          >
            <span className="text-[11px] uppercase tracking-[0.3em] font-bold border-b border-cocoa/20 py-2 group-hover:text-gold group-hover:border-gold transition-slow">
              Discover the full menu
            </span>
            <span className="text-xl transition-transform group-hover:translate-x-2 transition-slow">→</span>
          </Link>
        </div>
      </div>
    </section>
  );
};
