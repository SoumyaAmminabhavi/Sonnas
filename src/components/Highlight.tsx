import { env } from "~/env";

export const Highlight = () => (
  <section id="highlight" className="py-2xl bg-blush/20 relative overflow-hidden">
    {/* Decorative Elements */}
    <div className="absolute top-0 right-0 w-96 h-96 bg-rose/10 rounded-full blur-3xl -mr-48 -mt-48" />
    <div className="absolute bottom-0 left-0 w-96 h-96 bg-cream/30 rounded-full blur-3xl -ml-48 -mb-48" />

    <div className="container mx-auto px-lg relative z-10">
      <div className="bg-white/40 backdrop-blur-sm border border-white/60 p-2xl rounded-lg shadow-soft text-center max-w-4xl mx-auto">
        <h2 className="text-4xl md:text-5xl font-heading text-text-primary mb-md">
          Custom Cakes <span className="italic text-rose">Made for You</span>
        </h2>
        <p className="text-xl font-body text-text-secondary mb-xl leading-relaxed">
          Whether it&apos;s a grand wedding or an intimate celebration, we&apos;ll design a masterpiece that tastes as beautiful as it looks. Hand-painted details, delicate sugar flowers, and flavors that linger.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-lg">
          <a 
            href={`https://wa.me/${env.NEXT_PUBLIC_WHATSAPP_NUMBER}?text=${encodeURIComponent("Hi! I'd like to design my own cake")}`}
            className="bg-rose text-white font-body py-md px-2xl rounded-md hover:bg-rose-dark transition-default w-full sm:w-auto shadow-soft text-center"
          >
            Design Your Cake
          </a>
          <button className="bg-white text-text-primary font-body py-md px-2xl rounded-md border border-rose/20 hover:bg-cream transition-default w-full sm:w-auto">
            View Custom Gallery
          </button>
        </div>
      </div>
    </div>
  </section>
);
