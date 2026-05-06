import { navLinks } from "~/data/landing";

export const Footer = () => (
  <footer id="footer" className="bg-cream pt-32 pb-12 border-t border-cocoa/5">
    <div className="container mx-auto px-6 lg:px-12">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-20 mb-32">
        {/* Brand Block */}
        <div className="flex flex-col items-start gap-8">
           <div className="flex flex-col">
              <span className="font-heading text-2xl text-cocoa tracking-[0.3em] uppercase leading-none">
                SONNA&apos;S
              </span>
              <span className="text-[10px] uppercase tracking-[0.4em] text-gold mt-1 font-bold opacity-80">
                Pâtisserie & Café
              </span>
           </div>
           <p className="text-sm text-text-secondary leading-relaxed opacity-70 max-w-xs font-medium">
            Crafting luxury French desserts and artisanal cakes since 1992. Experience true elegance in every delicate detail.
           </p>
        </div>

        {/* Studio Links */}
        <div>
          <h3 className="text-[11px] uppercase tracking-[0.3em] font-bold text-cocoa mb-8">The Studio</h3>
          <ul className="space-y-4">
            {navLinks.map((link) => (
              <li key={link.name}>
                <a href={link.href} className="text-[11px] uppercase tracking-widest text-text-muted hover:text-gold transition-slow font-bold">
                  {link.name}
                </a>
              </li>
            ))}
          </ul>
        </div>

        {/* Contact Block */}
        <div>
          <h3 className="text-[11px] uppercase tracking-[0.3em] font-bold text-cocoa mb-8">Visit Us</h3>
          <ul className="space-y-6 text-sm text-text-secondary opacity-80 font-medium leading-relaxed">
            <li>
              Shop No. 5-7, Ground Floor, Akshay Colony,<br />
              Unkal Village, Hubballi, Karnataka 580021
            </li>
            <li>
              <a href="tel:+910000000000" className="text-gold font-bold tracking-widest">+91 (Studio Support)</a>
            </li>
          </ul>
        </div>

        {/* Newsletter / Correspondence */}
        <div>
          <h3 className="text-[11px] uppercase tracking-[0.3em] font-bold text-cocoa mb-8">Correspondence</h3>
          <p className="text-[10px] uppercase tracking-widest text-text-muted mb-8 font-bold">Join our private list for seasonal releases.</p>
          <div className="relative group">
            <input
              type="email"
              placeholder="Your email address"
              className="bg-transparent border-b border-cocoa/20 py-4 w-full text-xs font-medium focus:outline-none focus:border-gold transition-slow italic"
            />
            <button className="absolute right-0 top-1/2 -translate-y-1/2 text-[9px] uppercase tracking-[0.3em] font-bold text-cocoa hover:text-gold transition-slow">
              Join
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div className="pt-12 border-t border-cocoa/5 flex flex-col md:flex-row justify-between items-center gap-8">
        <p className="text-[9px] uppercase tracking-[0.3em] font-bold text-text-muted">
          © {new Date().getFullYear()} SONNA&apos;S PATISSERIE. All rights reserved.
        </p>
        <div className="flex items-center gap-10">
          {["Instagram", "Pinterest", "Facebook"].map((platform) => (
             <a key={platform} href="#" className="text-[9px] uppercase tracking-[0.3em] font-bold text-text-muted hover:text-gold transition-slow">
               {platform}
             </a>
          ))}
        </div>
      </div>
    </div>
  </footer>
);
