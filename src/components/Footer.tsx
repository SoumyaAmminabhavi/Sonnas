import { navLinks } from "~/data/landing";

export const Footer = () => (
  <footer id="footer" className="bg-cream pt-32 pb-16 border-t border-cocoa/5">
    <div className="container mx-auto px-8 lg:px-16">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-16 lg:gap-24 mb-32">
        {/* Brand Block - Widened container */}
        <div className="flex flex-col items-start gap-10 lg:col-span-1">
           <div className="flex flex-col">
              <span className="font-heading text-2xl text-cocoa tracking-[0.35em] uppercase leading-none">
                SONNA&apos;S
              </span>
              <span className="text-[10px] uppercase tracking-[0.45em] text-gold mt-2 font-extrabold opacity-90">
                Pâtisserie & Café
              </span>
           </div>
           <p className="text-base text-text-secondary leading-relaxed opacity-80 max-w-sm font-medium">
            Crafting luxury French desserts and artisanal cakes since 1992. Experience true elegance in every delicate detail.
           </p>
        </div>

        {/* Studio Links - Improved spacing */}
        <div className="lg:pl-8">
          <h3 className="text-[12px] uppercase tracking-[0.35em] font-extrabold text-cocoa mb-10">The Studio</h3>
          <ul className="space-y-6">
            {navLinks.map((link) => (
              <li key={link.name}>
                <a href={link.href} className="text-[12px] uppercase tracking-[0.2em] text-text-muted hover:text-gold transition-slow font-extrabold block py-1">
                  {link.name}
                </a>
              </li>
            ))}
          </ul>
        </div>

        {/* Contact Block - Improved width */}
        <div>
          <h3 className="text-[12px] uppercase tracking-[0.35em] font-extrabold text-cocoa mb-10">Visit Us</h3>
          <ul className="space-y-8 text-base text-text-secondary opacity-90 font-medium leading-relaxed">
            <li>
              Shop No. 5-7, Ground Floor, Akshay Colony,<br />
              Unkal Village, Hubballi, Karnataka 580021
            </li>
            <li className="pt-2">
              <a href="tel:+910000000000" className="text-gold font-extrabold tracking-[0.2em] text-[12px] uppercase border-b border-gold/30 pb-1 hover:border-gold transition-slow">+91 (Studio Support)</a>
            </li>
          </ul>
        </div>

        {/* Newsletter / Correspondence - Better spacing and layout */}
        <div className="lg:pl-4">
          <h3 className="text-[12px] uppercase tracking-[0.35em] font-extrabold text-cocoa mb-10">Correspondence</h3>
          <p className="text-[11px] uppercase tracking-[0.2em] text-text-muted mb-10 font-extrabold leading-relaxed">Join our private list for seasonal releases.</p>
          <div className="relative group max-w-sm">
            <input
              type="email"
              placeholder="Your email address"
              className="bg-transparent border-b-2 border-cocoa/10 py-5 w-full text-sm font-medium focus:outline-none focus:border-gold transition-slow italic placeholder:text-text-muted/50"
            />
            <button className="absolute right-0 top-1/2 -translate-y-1/2 text-[10px] uppercase tracking-[0.35em] font-extrabold text-cocoa hover:text-gold transition-slow bg-cream pl-4">
              Join
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Bar - Improved hierarchy */}
      <div className="pt-16 border-t border-cocoa/10 flex flex-col md:flex-row justify-between items-center gap-10">
        <p className="text-[10px] uppercase tracking-[0.4em] font-extrabold text-text-muted">
          © {new Date().getFullYear()} SONNA&apos;S PATISSERIE. All rights reserved.
        </p>
        <div className="flex items-center gap-12">
          {["Instagram", "Pinterest", "Facebook"].map((platform) => (
             <a key={platform} href="#" className="text-[10px] uppercase tracking-[0.35em] font-extrabold text-text-muted hover:text-gold transition-slow">
               {platform}
             </a>
          ))}
        </div>
      </div>
    </div>
  </footer>
);
