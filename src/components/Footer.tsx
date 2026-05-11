import { navLinks } from "~/data/landing";

export const Footer = () => (
  <footer id="footer" className="bg-beige/20 pt-2xl pb-lg border-t border-cream">
    <div className="container mx-auto px-lg">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-2xl mb-2xl">
        {/* Brand */}
        <div className="col-span-1 md:col-span-1">
          <h2 className="text-xl font-heading text-text-primary mb-md tracking-widest uppercase">
            SONNA&apos;S PATISSERIE & CAFE
          </h2>
          <p className="text-text-secondary font-body text-sm leading-6">
            Crafting luxury French desserts and artisanal cakes since 1992. Experience true elegance in every bite.
          </p>
        </div>

        {/* Quick Links */}
        <div className="col-span-1">
          <h3 className="text-sm uppercase tracking-widest font-heading mb-md">Quick Links</h3>
          <ul className="space-y-sm text-sm font-body text-text-secondary">
            {navLinks.map((link) => (
              <li key={link.name}>
                <a href={link.href} className="hover:text-rose transition-default">
                  {link.name}
                </a>
              </li>
            ))}
          </ul>
        </div>

        {/* Contact */}
        <div className="col-span-1">
          <h3 className="text-sm uppercase tracking-widest font-heading mb-md">Contact Us</h3>
          <ul className="space-y-sm text-sm font-body text-text-secondary">
            <li> 4TH Phase, Shop No. 5,6,7 Ground Floor, &quot;Aum Shree&quot; Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021</li>
            <li>
              <a href="tel:+919113231424" className="hover:text-rose transition-default">
                +91 9113231424
              </a>
            </li>

          </ul>
        </div>

        {/* Newsletter */}
        <div className="col-span-1">
          <h3 className="text-sm uppercase tracking-widest font-heading mb-md">Newsletter</h3>
          <p className="text-xs text-text-muted mb-md font-body">Join our list for exclusive seasonal releases.</p>
          <div className="flex">
            <input
              type="email"
              placeholder="Your email"
              className="bg-white border border-cream px-md py-sm w-full text-sm font-body focus:outline-none focus:border-rose transition-default"
            />
            <button className="bg-rose text-white px-lg py-sm text-sm font-body hover:bg-rose-dark transition-default">
              Join
            </button>
          </div>
        </div>
      </div>

      <div className="border-t border-cream pt-lg flex flex-col md:flex-row justify-between items-center gap-md">
        <p className="text-xs font-body text-text-muted">
          © {new Date().getFullYear()} SONNA&apos;S PATISSERIE & CAFE. All rights reserved.
        </p>
        <div className="flex space-x-lg">
          <a
            href="https://www.instagram.com/sonnas___/"
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs font-body text-text-muted hover:text-rose transition-default"
            aria-label="Follow us on Instagram"
          >
            Instagram
          </a>
          <a
            href="#"
            className="text-xs font-body text-text-muted hover:text-rose transition-default"
            aria-label="Follow us on Pinterest"
          >
            Pinterest
          </a>
          <a
            href="#"
            className="text-xs font-body text-text-muted hover:text-rose transition-default"
            aria-label="Follow us on Facebook"
          >
            Facebook
          </a>
        </div>

      </div>
    </div>
  </footer>
);
