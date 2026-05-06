import Link from "next/link";
import { navLinks } from "~/data/landing";

export const Navbar = () => (
  <nav className="fixed inset-x-0 top-0 z-50 glass-ivory py-5 transition-all duration-500">
    <div className="container mx-auto flex items-center justify-between px-8 lg:px-16">
      {/* Logo */}
      <Link href="/" className="flex flex-col group">
        <span className="font-heading text-xl lg:text-2xl text-cocoa tracking-[0.35em] uppercase leading-none transition-colors group-hover:text-gold">
          SONNA&apos;S
        </span>
        <span className="text-[9px] lg:text-[10px] uppercase tracking-[0.45em] text-gold mt-1.5 font-bold opacity-90">
          Pâtisserie & Café
        </span>
      </Link>

      {/* Links - Improved spacing and font-size */}
      <ul className="hidden md:flex items-center space-x-12 text-[12px] uppercase tracking-[0.2em] font-extrabold text-text-secondary">
        {navLinks.map((link) => (
          <li key={link.name}>
            <Link
              href={link.href}
              className="hover:text-gold transition-default relative group py-2"
            >
              {link.name}
              <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-[1.5px] bg-gold/50 transition-all duration-700 group-hover:w-full" />
            </Link>
          </li>
        ))}
      </ul>

      {/* Mobile Menu Trigger */}
      <div className="md:hidden flex items-center">
        <button className="text-cocoa p-2 group">
          <div className="w-7 h-[1.5px] bg-cocoa mb-2 transition-all group-hover:bg-gold" />
          <div className="w-5 h-[1.5px] bg-cocoa ml-auto transition-all group-hover:bg-gold" />
        </button>
      </div>
    </div>
  </nav>
);
