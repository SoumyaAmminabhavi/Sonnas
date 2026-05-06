import Link from "next/link";
import { navLinks } from "~/data/landing";

export const Navbar = () => (
  <nav className="fixed inset-x-0 top-0 z-50 glass-ivory py-4">
    <div className="container mx-auto flex items-center justify-between px-6 lg:px-12">
      {/* Logo */}
      <Link href="/" className="flex flex-col group">
        <span className="font-heading text-lg lg:text-xl text-cocoa tracking-[0.3em] uppercase leading-none transition-colors group-hover:text-gold">
          SONNA&apos;S
        </span>
        <span className="text-[8px] lg:text-[9px] uppercase tracking-[0.4em] text-gold mt-1 font-medium opacity-80">
          Pâtisserie & Café
        </span>
      </Link>

      {/* Links */}
      <ul className="hidden md:flex items-center space-x-10 text-[11px] uppercase tracking-[0.15em] font-bold text-text-secondary">
        {navLinks.map((link) => (
          <li key={link.name}>
            <Link
              href={link.href}
              className="hover:text-gold transition-default relative group py-2"
            >
              {link.name}
              <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-[1.5px] bg-gold/40 transition-all duration-500 group-hover:w-full" />
            </Link>
          </li>
        ))}
      </ul>

      {/* Mobile Menu Trigger */}
      <div className="md:hidden flex items-center">
        <button className="text-cocoa p-2">
          <div className="w-6 h-[1.5px] bg-cocoa mb-1.5" />
          <div className="w-4 h-[1.5px] bg-cocoa ml-auto" />
        </button>
      </div>
    </div>
  </nav>
);
