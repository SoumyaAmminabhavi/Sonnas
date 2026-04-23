import { HydrateClient } from "~/trpc/server";
import { Navbar } from "~/components/Navbar";
import { Hero } from "~/components/Hero";
import { FeaturedProducts } from "~/components/FeaturedProducts";
import { Categories } from "~/components/Categories";
import { AboutStory } from "~/components/AboutStory";
import { Highlight } from "~/components/Highlight";
import { Footer } from "~/components/Footer";

export default function Home() {
  return (
    <HydrateClient>
      <div className="flex flex-col min-h-screen">
        <Navbar />
        <main>
          <Hero />
          <FeaturedProducts />
          <Categories />
          <AboutStory />
          <Highlight />
        </main>
        <Footer />
      </div>
    </HydrateClient>
  );
}
