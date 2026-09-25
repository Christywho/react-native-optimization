import React, { useState } from 'react';
import { Image, ScrollView, Text } from 'react-native';
import catalog from '../data/catalog.json';

export default function ProductScreen({ route }: any) {
  const product = catalog.products.find(p => p.id === route.params.id)!;
  const [headerOpacity, setHeaderOpacity] = useState(1);
  return (
    <ScrollView
      scrollEventThrottle={1}
      onScroll={e => setHeaderOpacity(Math.max(0, 1 - e.nativeEvent.contentOffset.y / 200))}>
      <Image source={{ uri: product.image }} style={{ width: '100%', height: 300, opacity: headerOpacity }} />
      <Text>{product.title}</Text>
      <Text>{product.description}</Text>
    </ScrollView>
  );
}
