import Link from "next/link";

export const Hero = () => (
  <section
    id="home"
    className="relative h-screen flex items-center justify-center overflow-hidden"
  >
    {/* Background Image with Parallax-like effect */}
    <div
      className="absolute inset-0 bg-cover bg-center transition-transform duration-1000"
      style={{
        backgroundImage: "url('/images/hero-cake-india.png')",
      }}
    />

    {/* Stronger Soft Pink & Cream Overlay Gradient for readability */}
    <div className="absolute inset-0 bg-gradient-to-tr from-cream/95 via-blush/60 to-transparent z-0" />

    {/* Content */}
    <div className="relative z-10 container mx-auto px-lg text-center">
      <h1 className="text-5xl md:text-7xl lg:text-8xl font-heading text-text-primary mb-md leading-tight animate-fade-in drop-shadow-[0_2px_2px_rgba(255,255,255,0.8)]">
        <span style={{ color: "#5b1017ff" }}>Crafted with Love,</span><br />
        <span style={{ color: "#8c0f49ff" }}>Baked to Perfection</span>
      </h1>
      {/* <p className="text-lg md:text-xl font-body text-text-secondary mb-xl max-w-2xl mx-auto opacity-100 drop-shadow-sm">
        Experience the soft embrace of French patisserie tradition in the heart of Bengaluru, where every detail is a delicate dance of flavor and elegance.
      </p> */}
      <div className="flex justify-center items-center gap-md mb-xl animate-fade-in-up">
        <div className="flex items-center gap-sm bg-white/40 backdrop-blur-md px-md py-sm rounded-full border border-green-600/30 shadow-sm">
          <div className="w-4 h-4 border-2 border-green-600 flex items-center justify-center p-[2px]">
            <div className="w-full h-full bg-green-600 rounded-full" />
          </div>
          <span className="text-sm font-bold text-green-800 tracking-wide uppercase">100% Eggless & Vegetarian</span>
        </div>
      </div>
      <Link
        href="#highlight"
        className="inline-block bg-rose text-white font-body py-md px-2xl rounded-md hover:bg-rose-dark shadow-soft hover:shadow-medium transition-default transform hover:-translate-y-1"
      >
        Order Now
      </Link>
    </div>

    {/* Bottom Gradient Fade */}
    <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-cream to-transparent" />
  </section>
);
