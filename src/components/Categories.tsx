"use client";

import Image from "next/image";
import Link from "next/link";
import { api } from "~/trpc/react";

export const Categories = () => {
  const { data: categories, isLoading } = api.cake.getAllCategories.useQuery();

  return (
    <section id="categories" className="py-2xl bg-beige/30">
      <div className="container mx-auto px-lg">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-lg">
          {isLoading ? (
            // Premium Skeleton Loader for Categories
            Array.from({ length: 4 }).map((_, i) => (
              <div
                key={i}
                className="shrink-0 h-64 bg-white/50 animate-pulse rounded-lg overflow-hidden shadow-soft"
              />
            ))
          ) : (
            categories?.map((category) => (
              <Link
                key={category.id}
                href={`#cakes`}
                className="group relative h-64 rounded-lg overflow-hidden cursor-pointer shadow-soft hover:shadow-medium transition-default transform hover:-translate-y-1"
              >
                {category.image ? (
                  <Image
                    src={category.image}
                    alt={category.name}
                    fill
                    unoptimized
                    className="object-cover transition-transform duration-1000 group-hover:scale-110"
                  />
                ) : (
                  // Elegant Fallback if no image is uploaded
                  <div className="absolute inset-0 bg-cocoa/10 flex items-center justify-center font-heading text-cocoa/40">
                    🧁 {category.name}
                  </div>
                )}
                {/* Overlay - Darker for readability */}
                <div className="absolute inset-0 bg-cocoa/40 group-hover:bg-rose/40 transition-default" />

                {/* Content */}
                <div className="absolute inset-0 flex flex-col items-center justify-center text-white p-lg text-center">
                  <h3 className="text-xl font-heading mb-sm tracking-wide drop-shadow-md">
                    {category.name}
                  </h3>
                  <span className="opacity-0 group-hover:opacity-100 transform translate-y-4 group-hover:translate-y-0 transition-all duration-500 font-body text-xs uppercase tracking-widest border border-white px-md py-xs">
                    Explore
                  </span>
                </div>
              </Link>
            ))
          )}
        </div>
      </div>
    </section>
  );
};
