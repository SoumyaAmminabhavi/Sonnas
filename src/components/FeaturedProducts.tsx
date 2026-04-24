"use client";

import Image from "next/image";
import { api } from "~/trpc/react";
import { env } from "~/env";

export const FeaturedProducts = () => {
  const { data: cakes, isLoading } = api.cake.getAll.useQuery();

  return (
    <section id="cakes" className="py-2xl bg-cream">
      <div className="container mx-auto px-lg">
        <div className="text-center mb-2xl">
          <h2 className="text-4xl md:text-5xl font-heading text-text-primary mb-sm">
            Featured Delights
          </h2>
          <p className="text-text-secondary font-body text-center mx-auto w-full">
            Our signature creations, handcrafted daily with the finest seasonal ingredients.
          </p>
        </div>

        <div className="flex overflow-x-auto snap-x snap-mandatory gap-xl pb-lg hide-scrollbar" style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}>
          {isLoading ? (
            // Skeleton Loader
            Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="shrink-0 w-[280px] md:w-[320px] bg-white/50 animate-pulse rounded-lg overflow-hidden h-[500px]" />
            ))
          ) : (
            cakes?.map((cake) => (
              <div
                key={cake.id}
                className="group shrink-0 w-[280px] md:w-[320px] bg-white rounded-lg shadow-soft overflow-hidden transition-default hover:shadow-medium hover:scale-[1.02] snap-start"
              >
                <div className="relative h-72 overflow-hidden">
                  <Image
                    src={cake.image}
                    alt={cake.name}
                    fill
                    unoptimized
                    className="object-cover transition-transform duration-700 group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-black/5 opacity-0 group-hover:opacity-100 transition-default" />
                </div>
                <div className="p-lg flex flex-col items-center">
                  <h3 className="text-xl font-heading text-text-primary text-center mb-sm">
                    {cake.name}
                  </h3>
                  {cake.description && (
                    <p className="text-text-secondary font-body italic text-sm text-left w-full mb-md leading-relaxed flex-grow">
                      {cake.description}
                    </p>
                  )}
                  {cake.options && cake.options.length > 0 && (
                    <div className="w-full mt-auto">
                      <hr className="w-full border-t border-black/10 mb-md" />
                      <div className="flex flex-col gap-sm mb-md">
                        {cake.options.map((opt, i) => (
                          <div key={i} className="flex justify-between items-center text-sm font-body">
                            <span className="text-text-secondary">{opt.size} &middot; Serves {opt.serves}</span>
                            <span className="text-rose font-medium text-lg">{opt.price}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                  <a 
                    href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent(`Hi Sonna's! I am interested in ordering the ${cake.name}.`)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-xs text-xs uppercase tracking-widest text-text-muted border-b border-transparent hover:border-rose hover:text-rose transition-default cursor-pointer inline-flex items-center gap-2"
                  >
                    <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.888-.788-1.489-1.761-1.663-2.06-.173-.298-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51a12.8 12.8 0 0 0-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/></svg>
                    Order via WhatsApp
                  </a>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </section>
  );
};
