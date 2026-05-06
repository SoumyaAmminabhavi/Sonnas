import Link from "next/link";
import { navLinks } from "~/data/landing";

export const Navbar = () => (
  <nav className="fixed inset-x-0 top-0 z-50 bg-cream/80 backdrop-blur-md py-sm">
    <div className="container mx-auto flex items-center justify-between px-lg">
      {/* Logo */}
      <Link href="/" className="text-xl font-heading text-text-primary tracking-widest uppercase">
        SONNA&apos;S PATISSERIE & CAFE
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
{ link.name }
<span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-[1px] bg-gold/50 transition-all duration-500 group-hover:w-full" />
              </Link >
            </li >
          ))}
        </ul >

  {/* Mobile Menu Trigger - Refined hamburger */ }
  < button
className = "md:hidden flex flex-col items-end gap-1.5 z-[110] p-2"
onClick = {() => setIsOpen(!isOpen)}
aria - label="Toggle Menu"
  >
          <div className={`h-[1.5px] bg-cocoa transition-all duration-300 ${isOpen ? "w-6 rotate-45 translate-y-2" : "w-6"}`} />
          <div className={`h-[1.5px] bg-cocoa transition-all duration-300 ${isOpen ? "opacity-0" : "w-4"}`} />
          <div className={`h-[1.5px] bg-cocoa transition-all duration-300 ${isOpen ? "w-6 -rotate-45 -translate-y-1" : "w-5"}`} />
        </button >

  {/* Mobile Overlay - Clean luxury overlay */ }
  < div
className = {`fixed inset-0 bg-cream z-[100] flex flex-col items-center justify-center transition-all duration-700 ${isOpen ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
  }`}
        >
          <ul className="flex flex-col items-center space-y-10">
            {navLinks.map((link, idx) => (
              <li 
                key={link.name} 
                className={`transition-all duration-700 delay-[${idx * 100}ms] ${
                  isOpen ? "translate-y-0 opacity-100" : "translate-y-10 opacity-0"
                }`}
              >
                <Link
                  href={link.href}
                  className="font-heading text-4xl text-cocoa hover:text-gold"
                  onClick={() => setIsOpen(false)}
                >
                  {link.name}
                </Link>
              </li>
            ))}
          </ul>
          <div className="absolute bottom-12 flex flex-col items-center gap-4">
             <span className="text-[10px] uppercase tracking-[0.3em] font-bold text-gold">Handcrafted Excellence</span>
             <div className="w-px h-12 bg-gold/30" />
          </div>
        </div >
      </div >
    </nav >
  );
};
