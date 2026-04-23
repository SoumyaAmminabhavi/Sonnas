import Link from "next/link";
import { navLinks } from "~/data/landing";

export const Navbar = () => (
  <nav className="fixed inset-x-0 top-0 z-50 bg-cream/80 backdrop-blur-md py-sm">
    <div className="container mx-auto flex items-center justify-between px-lg">
      {/* Logo */}
      <Link href="/" className="text-xl font-heading text-text-primary tracking-widest uppercase">
        SONNA'S PATISSERIE & CAFE
      </Link>

      {/* Links */}
      <ul className="hidden md:flex space-x-xl text-sm font-body text-text-secondary">
        {navLinks.map((link) => (
          <li key={link.name}>
            <Link
              href={link.href}
              className="hover:text-rose transition-default relative group"
            >
              {link.name}
              <span className="absolute -bottom-1 left-0 w-0 h-px bg-rose transition-all duration-300 group-hover:w-full" />
            </Link>
          </li>
        ))}
      </ul>

      {/* Placeholder for small mobile menu or cart */}
      <div className="md:hidden">
        <button className="text-text-primary">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      </div>
    </div>
  </nav>
);
