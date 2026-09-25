import React from 'react';
import { Image, Text, TouchableOpacity } from 'react-native';
import { useCart } from '../context/CartContext';

export default function ProductCard({ product, width, onPress }: any) {
  const { add } = useCart();
  console.log('render card', product.id);
  return (
    <TouchableOpacity onPress={onPress} style={{ width, padding: 8 }}>
      <Image source={{ uri: product.image }} style={{ width: 64, height: 64 }} />
      <Text>{product.title}</Text>
      <Text>${product.price.toFixed(2)}</Text>
      <TouchableOpacity onPress={() => add(product.id)}><Text>Add</Text></TouchableOpacity>
    </TouchableOpacity>
  );
}
