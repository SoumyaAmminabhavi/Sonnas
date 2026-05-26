export interface NavLink {
  name: string;
  href: string;
}

export const navLinks: NavLink[] = [
  { name: "Home", href: "#home" },
  { name: "Cakes", href: "#cakes" },
  { name: "Custom Orders", href: "#highlight" },
  { name: "About", href: "#about" },
  { name: "Contact", href: "#footer" },
];

export * from "./products";

