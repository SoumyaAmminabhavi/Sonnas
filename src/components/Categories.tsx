import Image from "next/image";
import { categories } from "~/data/landing";

export const Categories = () => (
  <section id="categories" className="py-2xl bg-beige/30">
    <div className="container mx-auto px-lg">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-lg">
        {categories.map((category) => (
          <div
            key={category.id}
            className="group relative h-96 rounded-lg overflow-hidden cursor-pointer shadow-soft hover:shadow-medium transition-default transform hover:-translate-y-1"
          >
            <Image
              src={category.image}
              alt={category.name}
              fill
              className="object-cover transition-transform duration-1000 group-hover:scale-110"
            />
            {/* Overlay - Darker for readability */}
            <div className="absolute inset-0 bg-cocoa/40 group-hover:bg-rose/40 transition-default" />

            {/* Content */}
            <div className="absolute inset-0 flex flex-col items-center justify-center text-white p-lg text-center">
              <h3 className="text-3xl font-heading mb-md tracking-wide drop-shadow-md">
                {category.name}
              </h3>
              <span className="opacity-0 group-hover:opacity-100 transform translate-y-4 group-hover:translate-y-0 transition-all duration-500 font-body text-sm uppercase tracking-widest border border-white px-lg py-sm">
                Explore Category
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  </section>
);
