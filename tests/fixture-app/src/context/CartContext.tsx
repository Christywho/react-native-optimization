import React, { createContext, useContext, useState } from 'react';

type Item = { id: string; qty: number };
const CartContext = createContext<any>(null);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<Item[]>([]);
  const add = (id: string) =>
    setItems(prev => {
      const hit = prev.find(i => i.id === id);
      return hit ? prev.map(i => (i.id === id ? { ...i, qty: i.qty + 1 } : i)) : [...prev, { id, qty: 1 }];
    });
  return <CartContext.Provider value={{ items, add, count: items.length }}>{children}</CartContext.Provider>;
}

export const useCart = () => useContext(CartContext);
