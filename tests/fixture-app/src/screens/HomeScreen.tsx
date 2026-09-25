import React, { useEffect, useState } from 'react';
import { Dimensions, Image, ScrollView, Text, TextInput, TouchableOpacity, View } from 'react-native';
import _ from 'lodash';
import moment from 'moment';
import catalog from '../data/catalog.json';
import { useCart } from '../context/CartContext';
import ProductCard from '../components/ProductCard';

export default function HomeScreen({ navigation, searchIndex }: any) {
  const [query, setQuery] = useState('');
  const [width, setWidth] = useState(Dimensions.get('window').width);
  const cart = useCart();

  useEffect(() => {
    Dimensions.addEventListener('change', ({ window }) => setWidth(window.width));
  }, []);

  const q = query.toLowerCase();
  const matches = q
    ? searchIndex.filter((e: any) => e.haystack.includes(q)).map((e: any) => _.find(catalog.products, { id: e.id }))
    : catalog.products;

  return (
    <View style={{ flex: 1 }}>
      <TextInput value={query} onChangeText={setQuery} placeholder="Search" />
      <Text>Updated {moment().format('LLL')} · {cart.count} in cart</Text>
      <ScrollView>
        {matches.map((p: any) => (
          <ProductCard key={p.id} product={p} width={width} onPress={() => navigation.navigate('Product', { id: p.id })} />
        ))}
      </ScrollView>
    </View>
  );
}
